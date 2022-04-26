FROM node:17 as node-builder

WORKDIR /app
COPY package.json /app
COPY yarn.lock /app

ENV GENERATE_SOURCEMAP false

ARG NODE_OPTIONS=--openssl-legacy-provider --max-old-space-size=100000
RUN yarn install --immutable

COPY webpack.config.js /app
COPY assets/ /app/assets/
COPY public/ /app/public/
RUN yarn build

FROM php:8.1-fpm as php-builder

WORKDIR /app
RUN apt-get update && apt-get install -y libpng-dev zlib1g-dev git unzip
RUN docker-php-ext-configure gd && docker-php-ext-install -j$(nproc) gd
COPY composer.* /app/
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
RUN composer install --no-dev --no-interaction --no-progress --optimize-autoloader

FROM php:8.1-fpm as final

RUN docker-php-ext-install pdo_mysql
COPY --from=node-builder /app/node_modules/ ./node_modules/
COPY --from=node-builder /app/public/ ./public/
COPY --from=php-builder /app/vendor/ ./vendor/

RUN chown -R www-data:www-data /tmp

EXPOSE 8080
