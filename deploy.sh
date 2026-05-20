#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "⏳ Pulling latest code..."
git config pull.rebase false
git pull origin main

echo "⏳ Installing dependencies..."
composer install --no-dev --optimize-autoloader

echo "⏳ Running migrations..."
php artisan migrate --force

echo "⏳ Caching config, routes, views..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "⏳ Setting permissions..."
chmod -R 755 storage bootstrap/cache

echo "✅ Deployed successfully."
