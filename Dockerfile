FROM php:5.6.26-fpm-alpine

LABEL maintainer="longfei6671@163.com"

ADD conf/php.ini /usr/local/etc/php/php.ini
ADD conf/www.conf /usr/local/etc/php-fpm.d/www.conf

#Alpine packages
RUN apk add --update git make gcc g++ \
	openssl \
	openssl-dev \
	libc-dev \
	autoconf \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libmcrypt-dev \
	libpcre32 \
	bzip2 \
	libbz2 \
	libmemcached-dev \
	cyrus-sasl-dev \
	bzip2 \
	&& rm -rf /var/cache/apk/* 


RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install gd \
        && docker-php-ext-install mysqli \
        && docker-php-ext-install bz2 \
        && docker-php-ext-install zip \
        && docker-php-ext-install pdo \
        && docker-php-ext-install pdo_mysql \
        && docker-php-ext-install opcache

		
WORKDIR /usr/src/php/ext/

RUN set -xe && \
	curl -LO https://github.com/igbinary/igbinary/archive/2.0.4.tar.gz && \
	tar xzf 2.0.4.tar.gz && \
	cd igbinary-2.0.4 && phpize && ./configure CFLAGS="-O2 -g" --enable-igbinary --with-php-config=/usr/local/bin/php-config && make install && \
	echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini && \
	cd ../ && rm -rf igbinary
	
# Compile Memcached 
RUN set -xe && \
	curl -LO https://github.com/php-memcached-dev/php-memcached/archive/2.2.0.tar.gz && \
	tar xzf 2.2.0.tar.gz && cd php-memcached-2.2.0 && \
	phpize && ./configure --with-php-config=/usr/local/bin/php-config && make && make install && \
	echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini && \
	cd .. && rm -rf php-memcached 
	
# Compile PhpRedis
ENV PHPREDIS_VERSION=3.0.0

RUN git clone -b master https://github.com/phpredis/phpredis.git \
	&& docker-php-ext-configure phpredis \
	&& docker-php-ext-install phpredis \
	&& rm -rf phpredis
	

WORKDIR /usr/src/php/ext/
# Compile Phalcon
ENV PHALCON_VERSION=3.0.1
RUN set -xe && \
    curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
    tar xzf v${PHALCON_VERSION}.tar.gz && cd cphalcon-${PHALCON_VERSION}/build && sh install && \
    echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini && \
    cd ../.. && rm -rf v${PHALCON_VERSION}.tar.gz cphalcon-${PHALCON_VERSION} 

# Compile Mongo
RUN set -xe && \
	curl -LO https://github.com/mongodb/mongo-php-driver-legacy/archive/1.6.16.tar.gz && \
	tar xzf 1.6.16.tar.gz && cd mongo-php-driver-legacy-1.6.16  && phpize && ./configure && make && make install \
	&& make clean && echo "extension=mongo.so" > /usr/local/etc/php/conf.d/mongo.ini \
	&& cd ../.. && rm -rf 1.6.16.tar.gz mongo-php-driver-legacy-1.6.16


RUN docker-php-source extract \
	&& cd /usr/src/php/ext/bcmath \
	&& phpize && ./configure --with-php-config=/usr/local/bin/php-config && make && make install \
	&& make clean \
	&& docker-php-source delete

	
FROM php:5.6.26-fpm-alpine

LABEL maintainer="longfei6671@163.com"

RUN apk add --update openssl \
	openssl-dev \
	libc-dev \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libmcrypt-dev \
	libpcre32 \
	bzip2 \
	libbz2 \
	libmemcached-dev \
	cyrus-sasl-dev \
	bzip2 \
	&& rm -rf /var/cache/apk/* 

COPY --from=0 /usr/local/lib/php/extensions/no-debug-non-zts-20131226/* /usr/local/lib/php/extensions/no-debug-non-zts-20131226/
ADD conf/php.ini /usr/local/etc/php/php.ini
ADD conf/www.conf /usr/local/etc/php-fpm.d/www.conf

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install gd \
		&& docker-php-ext-install mcrypt \
        && docker-php-ext-install mysqli \
        && docker-php-ext-install bz2 \
        && docker-php-ext-install zip \
        && docker-php-ext-install pdo \
        && docker-php-ext-install pdo_mysql \
        && docker-php-ext-install opcache \
		&& docker-php-ext-install mcrypt \
		&& echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini \
		&& echo "extension=redis.so" > /usr/local/etc/php/conf.d/phpredis.ini \
		&& echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini \
		&& echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini \
		&& echo "extension=bcmath.so" > /usr/local/etc/php/conf.d/bcmath.ini \
		&& echo "extension=mongo.so" > /usr/local/etc/php/conf.d/mongo.ini

EXPOSE 9000

CMD ["php-fpm"]