# Stage 1: Build front-end assets using Node.js
FROM node:24-alpine AS prebuild-assets

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to install dependencies
COPY package*.json ./

# Copy the resources folder and any JS files needed for the build process
COPY resources ./resources
COPY *.js ./

# Install node dependencies and build the assets (assumes npm run build creates a production build)
RUN npm ci && npm run build

# Stage 2: Install PHP dependencies using Composer
FROM composer:2.8 AS prebuild-composer

# Set the working directory inside the container
WORKDIR /app

# Copy the entire application into the container
COPY . .

# Install PHP dependencies without development packages, optimize the autoloader, and remove migrations
RUN composer install --no-dev --no-interaction --no-progress --optimize-autoloader --ignore-platform-req=ext-* && \
    rm -rf ./vendor/laravel/sanctum/database/migrations/*

# Stage 3: Set up the application with PHP-Nginx
FROM trafex/php-nginx:3.6.0 AS build

# Switch to root user to install required packages
USER root

# Install necessary PHP extensions like zip, PDO for MySQL, and curl and update the Nginx configuration
RUN apk add --no-cache libzip-dev php83-zip php83-pdo_mysql php83-curl && \
    sed -i 's|/var/www/html|&/public|g' /etc/nginx/conf.d/default.conf

# Set the working directory inside the container to where Laravel will be located
WORKDIR /var/www/html

# Copy PHP application files from the prebuild-composer stage to the working directory
COPY --chown=nginx --from=prebuild-composer /app /var/www/html

# Copy the built assets from the prebuild-assets stage into the public/build directory
COPY --from=prebuild-assets /app/public/build /var/www/html/public/build

# Healthcheck script
COPY infra/docker/healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

# Nginx config
COPY infra/docker/nginx.conf /etc/nginx/conf.d/default.conf

# Laravel setup script
RUN mkdir -p /tmp/storage_public && \
    cp -R /var/www/html/storage/app/public/. /tmp/storage_public/
RUN mkdir -p /var/www/html/storage/app/public/documents /var/www/html/storage/logs
COPY infra/docker/laravel-setup.sh /var/www/html/laravel-setup.sh
RUN chmod +x /var/www/html/laravel-setup.sh

# Set the values of post_max_size and upload_max_filesize to 10M in the PHP configuration
RUN sed -i 's/post_max_size = .*/post_max_size = 10M/' /etc/php83/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 10M/' /etc/php83/php.ini

# Ensure the proper permissions are set for the web server to serve the application
RUN chown -R nobody:nobody /var/www/html

# Switch back to the unprivileged user for security purposes
USER nobody

# Expose healthcheck
HEALTHCHECK CMD /healthcheck.sh

ENTRYPOINT ["sh", "/var/www/html/laravel-setup.sh"]