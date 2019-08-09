ARG PHP_VERSION
FROM php:${PHP_VERSION}-fpm

ARG SWOOLE_VERSION

MAINTAINER huangzhhui <h@swoft.org>

# Version
ENV PHPREDIS_VERSION 4.0.0
ENV HIREDIS_VERSION 0.13.3

# Timezone
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezone

# Libs
RUN apt-get update \
    && apt-get install -y \
        curl \
        wget \
        git \
        zip \
        libz-dev \
        libssl-dev \
        libnghttp2-dev \
        libpcre3-dev \
        librabbitmq-dev \
        procps \
    && apt-get clean \
    && apt-get autoremove

# Composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer self-update --clean-backups

# PDO extension
RUN docker-php-ext-install pdo_mysql

#sockets extension
RUN docker-php-ext-install sockets

# Bcmath extension
RUN docker-php-ext-install bcmath

#amqp extension
# RUN wget http://pecl.php.net/get/amqp-1.9.4.tgz -O /tmp/amqp.tar.tgz \
#    && pecl install /tmp/amqp.tar.tgz \
#    && rm -rf /tmp/amqp.tar.tgz \
#    && docker-php-ext-enable amqp

# grpc extension
RUN wget http://pecl.php.net/get/grpc-1.21.3.tgz -O /tmp/grpc.tar.tgz \
    && pecl install /tmp/grpc.tar.tgz \
    && rm -rf /tmp/grpc.tar.tgz \
    && docker-php-ext-enable grpc

# Redis extension
RUN wget http://pecl.php.net/get/redis-${PHPREDIS_VERSION}.tgz -O /tmp/redis.tar.tgz \
    && pecl install /tmp/redis.tar.tgz \
    && rm -rf /tmp/redis.tar.tgz \
    && docker-php-ext-enable redis

# Hiredis
RUN wget https://github.com/redis/hiredis/archive/v${HIREDIS_VERSION}.tar.gz -O hiredis.tar.gz \
    && mkdir -p hiredis \
    && tar -xf hiredis.tar.gz -C hiredis --strip-components=1 \
    && rm hiredis.tar.gz \
    && ( \
        cd hiredis \
        && make -j$(nproc) \
        && make install \
        && ldconfig \
    ) \
    && rm -r hiredis

# Swoole extension
RUN wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-async-redis --enable-mysqlnd --enable-openssl --enable-http2 \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r swoole \
    && docker-php-ext-enable swoole

