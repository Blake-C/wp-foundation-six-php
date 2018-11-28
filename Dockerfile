FROM php:7.2-fpm
# Don't for get to update zend_extension and extension_dir in php.ini when
# updating php verions. The easiest way to update is to pull the same php
# version being used in the official wordpress docker image

# https://hub.docker.com/_/wordpress/

# To install new module
# docker-php-ext-install mysqli
# docker-php-ext-enable mysqli
# restart service
#	docker-composer restart

# install the PHP extensions we need
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libpng-dev \
		libxml2-dev \
		libxslt1-dev \
		libldap2-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
	docker-php-ext-install gd mysqli opcache zip bcmath calendar pcntl pdo_mysql soap wddx xsl ldap; \
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

RUN cd /tmp && wget http://xdebug.org/files/xdebug-2.6.1.tgz \
	&& tar -zxvf xdebug-2.6.1.tgz \
	&& cd xdebug-2.6.1 && phpize \
	&& ./configure --enable-xdebug && make && make install

# Copy xdebug configration for remote debugging
COPY ./php.ini /usr/local/etc/php/php.ini

WORKDIR /var/www/public_html
