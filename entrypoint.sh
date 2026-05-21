#!/usr/bin/env sh
# =============================================================================
# entrypoint.sh — Docker container startup for Compliance Engine
# Runs inside the container as the application entrypoint.
# =============================================================================
set -e

echo "[entrypoint] Starting Compliance Engine container..."

# ── Wait for MySQL to be ready ────────────────────────────────────────────────
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
MAX_WAIT=60
WAITED=0

echo "[entrypoint] Waiting for MySQL at ${DB_HOST}:${DB_PORT}..."
until php -r "
new PDO('mysql:host=${DB_HOST};port=${DB_PORT}', '${DB_USERNAME}', '${DB_PASSWORD}');
echo 'ok';
" 2>/dev/null | grep -q ok; do
  if [ "$WAITED" -ge "$MAX_WAIT" ]; then
    echo "[entrypoint] ERROR: MySQL not reachable after ${MAX_WAIT}s — aborting"
    exit 1
  fi
  sleep 2
  WAITED=$((WAITED + 2))
  echo "[entrypoint] Still waiting... (${WAITED}s)"
done
echo "[entrypoint] MySQL is ready"

# ── Clear bootstrap cache ─────────────────────────────────────────────────────
rm -f bootstrap/cache/config.php bootstrap/cache/routes-v7.php \
      bootstrap/cache/services.php bootstrap/cache/packages.php

# ── Ensure Telescope is disabled ─────────────────────────────────────────────
if grep -q "^TELESCOPE_ENABLED=" .env 2>/dev/null; then
  sed -i 's/^TELESCOPE_ENABLED=.*/TELESCOPE_ENABLED=false/' .env
else
  echo "TELESCOPE_ENABLED=false" >> .env
fi

# ── Run migrations ────────────────────────────────────────────────────────────
echo "[entrypoint] Running migrations..."
php artisan migrate --force

# ── Seed if compliance_forms_master is empty ──────────────────────────────────
FORM_COUNT=$(php artisan tinker --execute="echo DB::table('compliance_forms_master')->count();" 2>/dev/null | tail -1 || echo "0")
if [ "$FORM_COUNT" = "0" ]; then
  echo "[entrypoint] Seeding database..."
  php artisan db:seed --force
fi

# ── Storage symlink ───────────────────────────────────────────────────────────
[ -L "public/storage" ] || php artisan storage:link

# ── Optimize ──────────────────────────────────────────────────────────────────
php artisan config:cache
php artisan route:cache
php artisan view:cache

# ── Permissions ───────────────────────────────────────────────────────────────
chmod -R 755 storage bootstrap/cache

echo "[entrypoint] Bootstrap complete — starting PHP-FPM"
exec "$@"
