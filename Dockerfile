FROM alpine:edge

MAINTAINER qichengzx <qichengzx@gmail.com>

ENV TIMEZONE            Asia/Shanghai
ENV PHP_MEMORY_LIMIT    128M
ENV MAX_UPLOAD          10M
ENV PHP_MAX_FILE_UPLOAD 50
ENV PHP_MAX_POST        10M

RUN	echo "http://dl-4.alpinelinux.org/alpine/v3.7/community" >> /etc/apk/repositories && \
    apk update && apk upgrade &&\
	apk add --update tzdata && \
	cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
	echo "${TIMEZONE}" > /etc/timezone

RUN	apk add --update \
		 --no-cache \
	    ca-certificates \
	    openssh-client \
	    libmemcached-libs \
	    curl \
	    musl \
	    php7 \
		php7-mcrypt \
		php7-soap \
		php7-openssl \
		php7-gmp \
		php7-json \
		php7-dom \
		php7-pdo \
		php7-zip \
		php7-mysqli \
		php7-bcmath \
		php7-gd \
		php7-imagick \
		php7-pdo_mysql \
		php7-gettext \
		php7-xmlreader \
		php7-xmlrpc \
		php7-bz2 \
		php7-iconv \
		php7-curl \
		php7-ctype \
		php7-redis \
		php7-fpm \
		php7-phar \
		&& apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing --allow-untrusted \
    	gnu-libiconv

ENV PHPIZE_DEPS autoconf file g++ gcc libc-dev make pkgconf re2c php7-dev php7-pear yaml-dev 

RUN set -xe \
    && apk add --no-cache --repository "http://dl-cdn.alpinelinux.org/alpine/edge/testing" \
    --virtual .phpize-deps \
    $PHPIZE_DEPS \
    && sed -i 's/^exec $PHP -C -n/exec $PHP -C/g' $(which pecl) \
    && pecl channel-update pecl.php.net \
    && pecl install yaf \
    && echo "extension=yaf.so" > /etc/php7/conf.d/01_yaf.ini \
    && rm -rf /usr/share/php7 \
    && rm -rf /tmp/* \
    && apk del .phpize-deps

RUN curl -sS https://getcomposer.org/installer | \
    php7 -- --install-dir=/usr/bin --filename=composer

RUN	sed -i "s|;*daemonize\s*=\s*yes|daemonize = no|g" /etc/php7/php-fpm.conf && \
	sed -i "s|;*listen\s*=\s*127.0.0.1:9000|listen = 9000|g" /etc/php7/php-fpm.d/www.conf && \
	sed -i "s|;*listen\s*=\s*/||g" /etc/php7/php-fpm.d/www.conf && \
	sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini && \
	sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini && \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php7/php.ini && \
    
    # Cleaning up
	mkdir /www && \
	apk del tzdata && \
	rm -rf /var/cache/apk/*

# Fix for iconv: https://github.com/docker-library/php/issues/240
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

WORKDIR /www

VOLUME ["/www"]

EXPOSE 9000

ENTRYPOINT ["/usr/sbin/php-fpm7"]
