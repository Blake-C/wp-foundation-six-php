FROM php:8.0-fpm

# 8.0.3-fpm-alpine3.12

# Don't for get to update zend_extension and extension_dir in php.ini when
# updating php verions. The easiest way to update is to pull the same php
# version being used in the official wordpress docker image

# https://hub.docker.com/_/wordpress/

# To install new module
# docker-php-ext-install mysqli
# docker-php-ext-enable mysqli
# restart service
#	docker-composer restart

# persistent dependencies
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
	# Ghostscript is required for rendering PDF previews
	ghostscript \
	; \
	rm -rf /var/lib/apt/lists/*

# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
	libfreetype6-dev \
	libjpeg-dev \
	libmagickwand-dev \
	libpng-dev \
	libzip-dev \
	libxml2-dev \
	libxslt1-dev \
	libldap2-dev \
	; \
	\
	docker-php-ext-configure gd --with-freetype --with-jpeg; \
	docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
	docker-php-ext-configure gd \
	--with-freetype \
	--with-jpeg \
	; \
	docker-php-ext-install -j "$(nproc)" \
	bcmath \
	exif \
	gd \
	mysqli \
	opcache \
	zip \
	calendar \
	pcntl \
	pdo_mysql \
	soap \
	xsl \
	ldap \
    intl \
	; \
	# https://github.com/Imagick/imagick/issues/331
	# pecl install imagick-3.4.4; \
	# docker-php-ext-enable imagick opcache; \
	docker-php-ext-enable opcache; \
	\
	# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
	| awk '/=>/ { print $3 }' \
	| sort -u \
	| xargs -r dpkg-query -S \
	| cut -d: -f1 \
	| sort -u \
	| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# Xdebug
RUN apt-get update -y \
	&& apt-get install wget -y \
	&& apt-get install curl -y

RUN cd /tmp && wget http://xdebug.org/files/xdebug-3.0.3.tgz \
	&& tar -zxvf xdebug-3.0.3.tgz \
	&& cd xdebug-3.0.3 && phpize \
	&& ./configure --enable-xdebug && make && make install

# Copy xdebug configration for remote debugging
COPY ./php.ini /usr/local/etc/php/php.ini

WORKDIR /home/webdev/www/public_html
