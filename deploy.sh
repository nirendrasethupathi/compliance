#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Production deployment script for Compliance Engine (Laravel 12)
# MySQL-based infrastructure. Idempotent and rollback-safe.
# Usage: bash deploy.sh [--skip-git] [--seed] [--fresh]
# =============================================================================
set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
die()     { error "$*"; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${CYAN}  $*${RESET}"; \
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }

# ── Argument parsing ──────────────────────────────────────────────────────────
SKIP_GIT=false
RUN_SEED=false
FRESH_MIGRATE=false

for arg in "$@"; do
  case $arg in
    --skip-git)    SKIP_GIT=true ;;
    --seed)        RUN_SEED=true ;;
    --fresh)       FRESH_MIGRATE=true ;;
    *) warn "Unknown argument: $arg" ;;
  esac
done

# ── Resolve project root ──────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
PROJECT_ROOT="$SCRIPT_DIR"
PHP="$(command -v php || die 'php not found in PATH')"
ARTISAN="$PHP artisan"

DEPLOY_START=$(date +%s)
info "Project root : $PROJECT_ROOT"
info "PHP binary   : $PHP ($($PHP -r 'echo PHP_VERSION;'))"
info "Timestamp    : $(date '+%Y-%m-%d %H:%M:%S')"

# =============================================================================
# STEP 1 — Validate environment
# =============================================================================
section "STEP 1 — Validate Environment"

[[ -f ".env" ]] || die ".env file not found. Copy .env.example and configure it."

# Source .env values for shell-level validation
_env_val() { grep -E "^${1}=" .env | cut -d= -f2- | tr -d '"' | tr -d "'"; }

APP_KEY_VAL=$(_env_val APP_KEY)
DB_CONNECTION_VAL=$(_env_val DB_CONNECTION)
DB_HOST_VAL=$(_env_val DB_HOST)
DB_PORT_VAL=$(_env_val DB_PORT)
DB_DATABASE_VAL=$(_env_val DB_DATABASE)
DB_USERNAME_VAL=$(_env_val DB_USERNAME)
DB_PASSWORD_VAL=$(_env_val DB_PASSWORD)

[[ -n "$APP_KEY_VAL" ]]       || die "APP_KEY is empty in .env"
[[ "$APP_KEY_VAL" == base64:* ]] || die "APP_KEY must start with 'base64:'"
[[ "$DB_CONNECTION_VAL" == "mysql" ]] || die "DB_CONNECTION must be 'mysql', got: '$DB_CONNECTION_VAL'"
[[ -n "$DB_DATABASE_VAL" ]]   || die "DB_DATABASE is empty in .env"
[[ -n "$DB_USERNAME_VAL" ]]   || die "DB_USERNAME is empty in .env"

success "APP_KEY      : present"
success "DB_CONNECTION: $DB_CONNECTION_VAL"
success "DB_HOST      : $DB_HOST_VAL:$DB_PORT_VAL"
success "DB_DATABASE  : $DB_DATABASE_VAL"
success "DB_USERNAME  : $DB_USERNAME_VAL"

# Validate writable directories
for dir in storage storage/logs storage/framework/cache storage/framework/sessions \
           storage/framework/views bootstrap/cache; do
  if [[ ! -w "$dir" ]]; then
    warn "$dir is not writable — attempting chmod"
    chmod -R 775 "$dir" 2>/dev/null || die "Cannot make $dir writable"
  fi
done
success "Directory permissions OK"

# Ensure TELESCOPE_ENABLED=false is set (Telescope is dev-only)
if ! grep -q "^TELESCOPE_ENABLED=" .env; then
  echo "TELESCOPE_ENABLED=false" >> .env
  info "Added TELESCOPE_ENABLED=false to .env"
fi
# Force it off regardless of existing value
sed -i 's/^TELESCOPE_ENABLED=.*/TELESCOPE_ENABLED=false/' .env
success "Telescope disabled for deployment"

# =============================================================================
# STEP 2 — Pull latest code (optional)
# =============================================================================
section "STEP 2 — Source Code"

if [[ "$SKIP_GIT" == false ]]; then
  if [[ -d ".git" ]]; then
    info "Pulling latest code from origin/main..."
    git config pull.rebase false
    git pull origin main
    success "Git pull complete"
  else
    warn "No .git directory found — skipping git pull"
  fi
else
  info "Git pull skipped (--skip-git)"
fi

# =============================================================================
# STEP 3 — Clear ALL stale cache (must happen before composer)
# =============================================================================
section "STEP 3 — Clear Stale Cache"

info "Removing compiled bootstrap cache files..."
rm -f bootstrap/cache/config.php
rm -f bootstrap/cache/routes-v7.php
rm -f bootstrap/cache/services.php
rm -f bootstrap/cache/packages.php
rm -f bootstrap/cache/events.php

info "Running artisan cache clear commands..."
$ARTISAN config:clear  --quiet
$ARTISAN cache:clear   --quiet
$ARTISAN route:clear   --quiet
$ARTISAN view:clear    --quiet
$ARTISAN event:clear   --quiet 2>/dev/null || true

success "All stale caches cleared"

# =============================================================================
# STEP 4 — Install Composer dependencies
# =============================================================================
section "STEP 4 — Composer Dependencies"

command -v composer &>/dev/null || die "composer not found in PATH"

info "Installing production dependencies..."
composer install \
  --no-dev \
  --optimize-autoloader \
  --no-interaction \
  --prefer-dist \
  --no-progress

success "Composer install complete"

# =============================================================================
# STEP 5 — Verify MySQL connection
# =============================================================================
section "STEP 5 — MySQL Connection Check"

info "Testing database connection..."

DB_CHECK=$($PHP -r "
try {
    \$pdo = new PDO(
        'mysql:host=${DB_HOST_VAL};port=${DB_PORT_VAL};dbname=${DB_DATABASE_VAL};charset=utf8mb4',
        '${DB_USERNAME_VAL}',
        '${DB_PASSWORD_VAL}',
        [PDO::ATTR_TIMEOUT => 5, PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    echo 'connected';
} catch (PDOException \$e) {
    echo 'error:' . \$e->getMessage();
}
" 2>&1)

if [[ "$DB_CHECK" == "connected" ]]; then
  success "MySQL connection successful → ${DB_HOST_VAL}:${DB_PORT_VAL}/${DB_DATABASE_VAL}"
elif [[ "$DB_CHECK" == error:* ]]; then
  MSG="${DB_CHECK#error:}"
  error "MySQL connection failed: $MSG"
  echo ""
  echo "  Verify these values in .env:"
  echo "    DB_HOST     = $DB_HOST_VAL"
  echo "    DB_PORT     = $DB_PORT_VAL"
  echo "    DB_DATABASE = $DB_DATABASE_VAL"
  echo "    DB_USERNAME = $DB_USERNAME_VAL"
  echo ""
  echo "  Run this SQL as root to create the database and user:"
  echo "    CREATE DATABASE IF NOT EXISTS \`${DB_DATABASE_VAL}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  echo "    CREATE USER IF NOT EXISTS '${DB_USERNAME_VAL}'@'localhost' IDENTIFIED BY '<password>';"
  echo "    GRANT ALL PRIVILEGES ON \`${DB_DATABASE_VAL}\`.* TO '${DB_USERNAME_VAL}'@'localhost';"
  echo "    FLUSH PRIVILEGES;"
  die "Aborting deployment — fix MySQL connection first"
fi

# =============================================================================
# STEP 6 — Run migrations
# =============================================================================
section "STEP 6 — Database Migrations"

if [[ "$FRESH_MIGRATE" == true ]]; then
  warn "--fresh flag set: dropping all tables and re-running migrations"
  warn "This is DESTRUCTIVE. You have 5 seconds to cancel (Ctrl+C)..."
  sleep 5
  $ARTISAN migrate:fresh --force
else
  info "Running pending migrations..."
  $ARTISAN migrate --force
fi

success "Migrations complete"

# Verify critical tables exist
info "Verifying critical tables..."
TABLES_CHECK=$($PHP -r "
\$pdo = new PDO(
    'mysql:host=${DB_HOST_VAL};port=${DB_PORT_VAL};dbname=${DB_DATABASE_VAL};charset=utf8mb4',
    '${DB_USERNAME_VAL}', '${DB_PASSWORD_VAL}'
);
\$required = ['users','tenants','branches','compliance_forms_master','compliance_sections',
              'compliance_status','sessions','cache','jobs','migrations'];
\$missing = [];
foreach (\$required as \$t) {
    \$r = \$pdo->query(\"SHOW TABLES LIKE '\$t'\");
    if (!\$r->fetch()) \$missing[] = \$t;
}
echo empty(\$missing) ? 'ok' : 'missing:' . implode(',', \$missing);
" 2>&1)

if [[ "$TABLES_CHECK" == "ok" ]]; then
  success "All critical tables verified"
elif [[ "$TABLES_CHECK" == missing:* ]]; then
  MISSING="${TABLES_CHECK#missing:}"
  die "Missing tables after migration: $MISSING — check migration files"
fi

# =============================================================================
# STEP 7 — Run seeders
# =============================================================================
section "STEP 7 — Database Seeders"

# Check if compliance_forms_master is empty (needs seeding)
FORM_COUNT=$($PHP -r "
\$pdo = new PDO(
    'mysql:host=${DB_HOST_VAL};port=${DB_PORT_VAL};dbname=${DB_DATABASE_VAL};charset=utf8mb4',
    '${DB_USERNAME_VAL}', '${DB_PASSWORD_VAL}'
);
echo \$pdo->query('SELECT COUNT(*) FROM compliance_forms_master')->fetchColumn();
" 2>&1)

if [[ "$RUN_SEED" == true ]]; then
  info "Running seeders (--seed flag)..."
  $ARTISAN db:seed --force
  success "Seeders complete"
elif [[ "$FORM_COUNT" == "0" ]]; then
  info "compliance_forms_master is empty — running bootstrap seeder..."
  $ARTISAN db:seed --force
  success "Bootstrap seeding complete"
else
  info "Database already seeded ($FORM_COUNT forms found) — skipping"
  info "Use --seed to force re-seed"
fi

# =============================================================================
# STEP 8 — Storage symlink
# =============================================================================
section "STEP 8 — Storage Symlink"

if [[ -L "public/storage" ]]; then
  success "Storage symlink already exists"
else
  $ARTISAN storage:link
  success "Storage symlink created"
fi

# =============================================================================
# STEP 9 — Optimize Laravel for production
# =============================================================================
section "STEP 9 — Laravel Optimization"

info "Caching configuration..."
$ARTISAN config:cache

info "Caching routes..."
$ARTISAN route:cache

info "Caching views..."
$ARTISAN view:cache

success "Laravel optimization complete"

# =============================================================================
# STEP 10 — Fix permissions
# =============================================================================
section "STEP 10 — File Permissions"

chmod -R 755 storage bootstrap/cache
find storage -type f -exec chmod 644 {} \; 2>/dev/null || true
success "Permissions set"

# =============================================================================
# STEP 11 — Queue worker restart signal
# =============================================================================
section "STEP 11 — Queue Workers"

info "Sending restart signal to queue workers..."
$ARTISAN queue:restart 2>/dev/null || warn "queue:restart failed (workers may not be running)"

# Check if supervisor is managing queue workers
if command -v supervisorctl &>/dev/null; then
  supervisorctl reread  2>/dev/null || true
  supervisorctl update  2>/dev/null || true
  supervisorctl restart compliance-worker:* 2>/dev/null || \
    warn "Supervisor process 'compliance-worker' not found — start it manually"
  success "Supervisor workers restarted"
else
  warn "supervisorctl not found — start queue worker manually:"
  warn "  php artisan queue:work --sleep=3 --tries=3 --max-time=3600 &"
fi

# =============================================================================
# STEP 12 — Health check
# =============================================================================
section "STEP 12 — Health Check"

HEALTH=$($ARTISAN tinker --execute="
try {
    \DB::connection()->getPdo();
    \$forms  = \DB::table('compliance_forms_master')->count();
    \$sects  = \DB::table('compliance_sections')->count();
    \$users  = \DB::table('users')->count();
    \$migs   = \DB::table('migrations')->count();
    echo json_encode([
        'db'         => 'connected',
        'forms'      => \$forms,
        'sections'   => \$sects,
        'users'      => \$users,
        'migrations' => \$migs,
    ]);
} catch (\Exception \$e) {
    echo json_encode(['db' => 'error', 'message' => \$e->getMessage()]);
}
" 2>/dev/null | tail -1 || echo '{"db":"unknown"}')

info "Health check result: $HEALTH"

DB_STATUS=$(echo "$HEALTH" | $PHP -r "
\$d = json_decode(file_get_contents('php://stdin'), true);
echo \$d['db'] ?? 'unknown';
" 2>/dev/null || echo "unknown")

if [[ "$DB_STATUS" == "connected" ]]; then
  success "Database: connected"
else
  warn "Database health check returned: $DB_STATUS"
fi

# =============================================================================
# Summary
# =============================================================================
DEPLOY_END=$(date +%s)
ELAPSED=$(( DEPLOY_END - DEPLOY_START ))

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║   ✅  DEPLOYMENT COMPLETE                ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  Duration   : ${ELAPSED}s"
echo -e "  Environment: $(grep '^APP_ENV=' .env | cut -d= -f2)"
echo -e "  App URL    : $(grep '^APP_URL=' .env | cut -d= -f2)"
echo -e "  Database   : ${DB_DATABASE_VAL} @ ${DB_HOST_VAL}:${DB_PORT_VAL}"
echo ""
echo -e "  Next steps:"
echo -e "  • Verify app: curl -I \$(grep '^APP_URL=' .env | cut -d= -f2)/up"
echo -e "  • Check logs: tail -f storage/logs/laravel.log"
echo -e "  • Queue work: php artisan queue:work --sleep=3 --tries=3"
echo -e "  • Scheduler : add to crontab → * * * * * php $(pwd)/artisan schedule:run"
echo ""
