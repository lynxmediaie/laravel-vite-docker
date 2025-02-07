# Use a lightweight Linux base image
FROM debian:latest as ddns

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    cron \
    vim \
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Create the working directory and script
WORKDIR /duckdns

# Add the script content
RUN echo "#!/bin/bash" > duck.sh && \
    echo "echo url=\"https://www.duckdns.org/update?domains=lynxmedia&token=16c33c36-dc01-46c4-8e1a-3ca4de004fbe&ip=\" | curl -k -o /duckdns/duck.log -K -" >> duck.sh && \
    chmod 700 duck.sh

# Set up the crontab entry
RUN echo "*/5 * * * * /duckdns/duck.sh >/dev/null 2>&1" > /etc/cron.d/duckdns && \
    chmod 0644 /etc/cron.d/duckdns

# Stage 1: Build
FROM php:8.2-fpm-alpine AS builder

# Set working directory
WORKDIR /var/www/html

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so

# Install system dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    freetype-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    icu-dev \
    make \
    autoconf \
    gcc \
    g++ \
    libtool \
    pkgconf \
    nodejs \
    npm \
    openrc \
    supervisor \
    oniguruma \
    oniguruma-dev \
    linux-headers \
    argon2-dev

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add --no-cache gnu-libiconv

# Rebuild PHP with required extensions
RUN docker-php-source extract && \
    docker-php-ext-configure mbstring --enable-mbstring && \
    docker-php-ext-configure sockets && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install -j$(nproc) gd mbstring pdo pdo_mysql bcmath intl opcache sockets && \
    docker-php-source delete

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer --version && \
    ls -l

# Set Composer to allow running as root
ENV COMPOSER_ALLOW_SUPERUSER=1

# Copy Composer files explicitly
COPY ./../../src/composer.json ./../../src/composer.lock ./

# Copy all application files to the container
COPY ./../../src /var/www/html

# Install backend dependencies
RUN composer install --no-dev --optimize-autoloader

# Install frontend dependencies and build
RUN npm install && npm run build

# Install Laravel cache
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Stage 2: Production
FROM nginx:1.25-alpine AS production

# Set working directory
WORKDIR /var/www/html

# Install necessary dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    libpng \
    libjpeg-turbo \
    libwebp \
    libxpm \
    freetype \
    icu-libs \
    libxml2 \
    oniguruma \
    openrc \
    argon2-dev \
    python3 \
    certbot \
    supervisor \
    py3-pip \
    dcron

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add --no-cache gnu-libiconv

# Copy PHP-FPM binary from the builder stage
COPY --from=builder /usr/local/sbin/php-fpm /usr/local/sbin/php-fpm

# Copy application files from the builder stage
COPY --from=builder /var/www/html /var/www/html

# Copy built frontend assets
COPY --from=builder /var/www/html/public/build /var/www/html/public/build

# Copy DuckDNS script and crontab
COPY --from=ddns /duckdns /duckdns
COPY --from=ddns /etc/cron.d/duckdns /etc/cron.d/duckdns

RUN crontab /etc/cron.d/duckdns

RUN which php-fpm || (echo "PHP-FPM not installed!" && exit 1)

# Configure Nginx
COPY /docker/prod/default.conf /etc/nginx/conf.d/

# Copy Supervisor configuration
COPY /docker/prod/supervisord.conf /etc/supervisord.conf

COPY /docker/prod/php-fpm.conf /usr/local/etc/php-fpm.conf

# Copy SSL certificate files
COPY /docker/prod/privkey.pem /etc/letsencrypt/live/lynxmedia.ie/privkey.pem
COPY /docker/prod/fullchain.pem /etc/letsencrypt/live/lynxmedia.ie/fullchain.pem

RUN echo "0 0,12 * * * certbot renew --quiet && nginx -s reload" > /etc/cron.d/certbot-renew \
    && chmod 0644 /etc/cron.d/certbot-renew \
    && crontab /etc/cron.d/certbot-renew

RUN mkdir -p /var/log/php
RUN  chown -R nginx:nginx /var/log/php
RUN  chmod -R 755 /var/log/php

# Create Nginx cache directories and set permissions
RUN mkdir -p /var/cache/nginx /var/run && \
    chown -R nginx:nginx /var/cache/nginx /var/run && \
    addgroup -S nginx || true && adduser -S -G nginx nginx || true && \
    chown -R nginx:nginx /var/www/html && \
    chmod -R 755 /var/www/html

# Create log directory and set permissions
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chmod -R 777 /var/log/nginx

# Create necessary directories and set permissions for Nginx
RUN mkdir -p /var/cache/nginx/client_temp /var/log/nginx && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx && \
    chmod -R 755 /var/cache/nginx /var/log/nginx

RUN mkdir /var/log/supervisor && \
    chown -R root:root /var/log/supervisor && \
    chmod -R 755 /var/log/supervisor

# Expose port 80
EXPOSE 80 443

# Start Supervisor and Cron to manage PHP-FPM, Nginx, and DuckDNS
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
