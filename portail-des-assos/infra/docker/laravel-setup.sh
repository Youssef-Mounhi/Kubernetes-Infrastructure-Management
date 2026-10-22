#!/bin/sh
# docker/entrypoint.sh
#
# Preparation and optimization script for the laravel application.
# This script is executed when the Docker container starts.

set -eu

echo "[Laravel-setup] Starting application setup..."

###############################################################################
# 1. Cleanup caches
###############################################################################
php artisan config:clear      || true
php artisan cache:clear       || true
php artisan route:clear       || true
php artisan view:clear        || true
php artisan event:clear       || true

###############################################################################
# 2. Set up and optimize the application
###############################################################################
php artisan config:cache      --no-interaction
php artisan route:cache       --no-interaction
php artisan view:cache        --no-interaction
php artisan event:cache       --no-interaction
php artisan optimize          --no-interaction
php artisan storage:link      --no-interaction

###############################################################################
# 3. Run migrations
# Force because in production environment
###############################################################################
php artisan migrate --force --no-interaction 

###############################################################################
# 3. Create and set permissions for storage and cache directories
###############################################################################
mkdir -p /var/www/html/storage/app/public/documents /var/www/html/storage/logs
chown -R nobody:nobody /var/www/html/storage/app/public/documents /var/www/html/storage/logs

###############################################################################
# 4. Run Supervisor
###############################################################################
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf


echo "[Laravel-setup] application setup completed successfully."
exit 0