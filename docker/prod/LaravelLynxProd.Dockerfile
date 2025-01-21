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




#RUN wget https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz && \
#    tar -xvzf libiconv-1.17.tar.gz && \
#    cd libiconv-1.17 && \
#    ./configure --prefix=/usr && \
#    make && \
#    make install && \
#    cd .. && \
#    rm -rf libiconv-1.17 libiconv-1.17.tar.gz



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

RUN ls

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
RUN apk add --no-cache bash curl libpng libjpeg-turbo libwebp libxpm freetype icu-libs libxml2 openrc supervisor oniguruma argon2-dev

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add --no-cache gnu-libiconv

# Copy PHP-FPM binary from the builder stage
COPY --from=builder /usr/local/sbin/php-fpm /usr/local/sbin/php-fpm

# Copy application files from the builder stage
COPY --from=builder /var/www/html /var/www/html

# Copy built frontend assets
COPY --from=builder /var/www/html/public/build /var/www/html/public/build

RUN which php-fpm || (echo "PHP-FPM not installed!" && exit 1)

# Configure Nginx
COPY /docker/prod/default.conf /etc/nginx/conf.d/

# Copy Supervisor configuration
COPY /docker/prod/supervisord.conf /etc/supervisord.conf

COPY /docker/prod/php-fpm.conf /usr/local/etc/php-fpm.conf

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
EXPOSE 80

# Start Supervisor to manage PHP-FPM and Nginx
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
