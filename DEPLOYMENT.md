# Compliance Engine — Production Deployment Guide

## Stack Summary

| Layer | Technology |
|---|---|
| Framework | Laravel 12 / PHP 8.2+ |
| ORM | Eloquent |
| Database | MySQL 8.0+ (utf8mb4 / utf8mb4_unicode_ci) |
| Session | database → `sessions` table |
| Cache | database → `cache` table |
| Queue | database → `jobs` table |
| Scheduler | `compliance:check-due` (daily) |
| PDF | dompdf + fpdi + knp-snappy |
| Dev tooling | Telescope (disabled in production) |

---

## Environment Variables Reference

```ini
APP_NAME=Laravel
APP_ENV=production
APP_KEY=base64:<generated>
APP_DEBUG=false
APP_URL=https://yourdomain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=u494785662_compliance
DB_USERNAME=u494785662_compliance
DB_PASSWORD=Compliance@2026

SESSION_DRIVER=database
QUEUE_CONNECTION=database
CACHE_STORE=database

TELESCOPE_ENABLED=false
DEPLOY_SECRET=<strong-random-secret>
```

---

## MySQL Setup (run once as root)

```sql
CREATE DATABASE IF NOT EXISTS `u494785662_compliance`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'u494785662_compliance'@'localhost'
  IDENTIFIED BY 'Compliance@2026';

GRANT ALL PRIVILEGES ON `u494785662_compliance`.*
  TO 'u494785662_compliance'@'localhost';

FLUSH PRIVILEGES;
```

Verify:
```bash
mysql -h 127.0.0.1 -u u494785662_compliance -p'Compliance@2026' \
  u494785662_compliance -e "SELECT 'OK';"
```

---

## Deployment Methods

### Method 1 — Linux Server (recommended)

```bash
# First deployment
bash deploy.sh --seed

# Subsequent deployments (no re-seed)
bash deploy.sh

# Force re-seed (idempotent — safe to repeat)
bash deploy.sh --seed

# Skip git pull (manual code update)
bash deploy.sh --skip-git --seed

# Nuclear reset (DESTROYS ALL DATA)
bash deploy.sh --fresh --seed
```

### Method 2 — Shared Hosting (web hook)

Add `DEPLOY_SECRET=your-secret` to `.env`, then trigger:

```
# Deploy only
https://yourdomain.com/deploy.php?token=your-secret

# Deploy + seed
https://yourdomain.com/deploy.php?token=your-secret&seed=1
```

### Method 3 — Docker

```bash
# Build
docker build -t compliance-engine .

# Run (entrypoint.sh handles migrations automatically)
docker run -d \
  --name compliance \
  -p 80:80 \
  -e DB_HOST=mysql \
  -e DB_DATABASE=u494785662_compliance \
  -e DB_USERNAME=u494785662_compliance \
  -e DB_PASSWORD=Compliance@2026 \
  compliance-engine
```

---

## Manual Step-by-Step Commands

Run these in order on a fresh server:

```bash
# 1. Clear all stale cache
rm -f bootstrap/cache/config.php bootstrap/cache/routes-v7.php \
      bootstrap/cache/services.php bootstrap/cache/packages.php
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# 2. Ensure Telescope is disabled
echo "TELESCOPE_ENABLED=false" >> .env

# 3. Install dependencies
composer install --no-dev --optimize-autoloader

# 4. Run all migrations (creates 90+ tables)
php artisan migrate --force

# 5. Verify migration status
php artisan migrate:status

# 6. Seed compliance forms and sections
php artisan db:seed --force

# 7. Create storage symlink
php artisan storage:link

# 8. Optimize for production
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 9. Fix permissions
chmod -R 755 storage bootstrap/cache
```

---

## Queue Worker Setup

### Option A — Supervisor (recommended for VPS)

Install supervisor config:
```bash
sudo cp supervisord.conf /etc/supervisor/conf.d/compliance.conf
# Edit /etc/supervisor/conf.d/compliance.conf — update paths to match your server
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start compliance-worker:*
sudo supervisorctl start compliance-batch-worker:*
sudo supervisorctl start compliance-scheduler
```

Check status:
```bash
sudo supervisorctl status
```

### Option B — Crontab (shared hosting / simple VPS)

```bash
crontab -e
```

Add:
```cron
# Laravel scheduler (runs every minute, executes due commands)
* * * * * cd /path/to/project && php artisan schedule:run >> /dev/null 2>&1

# Queue worker (restart every hour to prevent memory leaks)
0 * * * * cd /path/to/project && php artisan queue:work --stop-when-empty --tries=3 >> /dev/null 2>&1
```

### Option C — systemd service

```ini
# /etc/systemd/system/compliance-worker.service
[Unit]
Description=Compliance Engine Queue Worker
After=network.target mysql.service

[Service]
User=www-data
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/php artisan queue:work database --sleep=3 --tries=3 --max-time=3600
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable compliance-worker
sudo systemctl start compliance-worker
sudo systemctl status compliance-worker
```

---

## Health Check

```bash
# Via curl
curl https://yourdomain.com/health

# Expected response (200 OK)
{
  "status": "ok",
  "database": "ok",
  "cache": "ok",
  "queues": "ok (pending:0 failed:0)",
  "storage": "ok",
  "forms": "ok (34 forms)"
}
```

---

## Compliance Form Verification

After deployment, verify these critical forms are accessible:

```bash
BASE="https://yourdomain.com/api/compliance/forms"

# CLRA Forms
curl -s "$BASE/formXII"   | head -c 100
curl -s "$BASE/formXIII"  | head -c 100
curl -s "$BASE/formXIV"   | head -c 100
curl -s "$BASE/formXXII"  | head -c 100
curl -s "$BASE/formXXIII" | head -c 100

# Factories Act
curl -s "$BASE/formB"     | head -c 100

# Verify seeded data
php artisan tinker --execute="
echo 'Forms: '   . DB::table('compliance_forms_master')->count();
echo ' Sections: ' . DB::table('compliance_sections')->count();
echo ' Tenants: '  . DB::table('tenants')->count();
"
```

---

## Troubleshooting

### App still connects to SQLite after setting DB_CONNECTION=mysql

```bash
# The compiled config cache is overriding .env
rm -f bootstrap/cache/config.php
php artisan config:clear
php artisan config:cache
```

### SQLSTATE[42S02]: Base table or view not found

```bash
# Migrations have not run — execute them
php artisan migrate --force

# Check which migrations are pending
php artisan migrate:status | grep Pending
```

### Telescope flooding logs with SQLite errors

```bash
# Telescope is a dev-only package — disable it
echo "TELESCOPE_ENABLED=false" >> .env
php artisan config:clear
php artisan config:cache
```

### CleanBootstrapSeeder fails with syntax error

The seeder previously used `PRAGMA foreign_keys = OFF` (SQLite syntax).
It has been fixed to use `SET FOREIGN_KEY_CHECKS=0` (MySQL syntax).
If you see this error, pull the latest code and re-run:
```bash
php artisan db:seed --class=CleanBootstrapSeeder --force
```

### Migrations fail mid-way (partial run)

```bash
# Check which migrations ran
php artisan migrate:status

# Re-run only pending migrations
php artisan migrate --force

# If a migration is stuck in a broken state, roll it back
php artisan migrate:rollback --step=1
php artisan migrate --force
```

### Queue jobs not processing

```bash
# Check pending jobs
php artisan tinker --execute="echo DB::table('jobs')->count();"

# Check failed jobs
php artisan tinker --execute="echo DB::table('failed_jobs')->count();"

# Retry failed jobs
php artisan queue:retry all

# Start a worker manually
php artisan queue:work --sleep=3 --tries=3 --verbose
```

### Storage symlink missing (file uploads broken)

```bash
php artisan storage:link
ls -la public/storage  # should be a symlink → ../storage/app/public
```

---

## Production Best Practices

1. Never commit `.env` to git — use `.env.example` as template
2. Set `APP_DEBUG=false` in production — never expose stack traces
3. Set `TELESCOPE_ENABLED=false` — Telescope is dev-only
4. Use `DEPLOY_SECRET` env var for the web deploy hook — never hardcode
5. Run `php artisan config:cache` after every `.env` change
6. Monitor `storage/logs/laravel.log` for errors
7. Set up log rotation: `logrotate /etc/logrotate.d/compliance`
8. Run `php artisan queue:retry all` after fixing failed jobs
9. Back up MySQL before running `migrate:fresh` or `db:seed`
10. Use `--no-dev` with composer in production — never install dev packages

---

## Files Created / Modified

| File | Purpose |
|---|---|
| `deploy.sh` | Full Linux deployment script (12 steps) |
| `entrypoint.sh` | Docker container startup script |
| `supervisord.conf` | Supervisor config for queue workers + scheduler |
| `public/deploy.php` | Secure web-based deployment webhook |
| `app/Http/Controllers/HealthController.php` | GET /health endpoint |
| `routes/web.php` | Added /health route |
| `config/queue.php` | Fixed sqlite fallback → mysql |
| `database/seeders/CleanBootstrapSeeder.php` | Fixed PRAGMA → SET FOREIGN_KEY_CHECKS |
