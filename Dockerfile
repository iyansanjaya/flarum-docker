# Dockerfile untuk Flarum

# --- STAGE 1: Composer ---
# Kita gunakan image Composer resmi untuk menginstal dependensi secara efisien
FROM composer:2 as composer
WORKDIR /app
COPY src/composer.json src/composer.lock ./
# --ignore-platform-reqs agar tidak error meskipun PHP lokal berbeda
RUN composer install --no-dev --no-scripts --ignore-platform-reqs

# --- STAGE 2: PHP-FPM + Nginx ---
# Kita gunakan image dasar yang sudah menyertakan PHP-FPM dan Nginx
FROM webdevops/php-nginx:8.3-alpine

# Setel direktori kerja di dalam kontainer
WORKDIR /app

# Instal ekstensi PHP yang dibutuhkan oleh Flarum
# Ini menyelesaikan masalah 'exif' dan lainnya secara permanen
RUN apk add --no-cache libzip-dev && docker-php-ext-install zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd exif bcmath sockets intl pdo_mysql

# Salin file konfigurasi Nginx kustom kita
# Ini menyelesaikan masalah routing dan error 404
COPY nginx.conf /opt/docker/etc/nginx/vhost.conf

# Salin seluruh kode sumber Flarum dari direktori 'src' lokal kita
COPY --chown=application:application src/ .

# Salin dependensi 'vendor' yang sudah diinstal dari Stage 1
COPY --from=composer --chown=application:application /app/vendor/ ./vendor/
