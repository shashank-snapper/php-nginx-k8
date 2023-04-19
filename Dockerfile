FROM php:8.1.1-fpm

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests libpq-dev wget gnupg -y \
		git \
        unzip \
        libicu-dev \
        zlib1g-dev \
        libssl-dev \
        pkg-config \
        libpq-dev \
        iputils-ping \
        libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN set -xe \
    && docker-php-ext-configure \
        intl \
    && docker-php-ext-install \
        intl \
        opcache \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        soap \
        sockets \
    && pecl install \
        apcu \
        xdebug \
        mongodb \
        redis \
    && docker-php-ext-enable \
        apcu \
        xdebug \
        mongodb \
        redis
# curl
RUN apt-get install -y curl

COPY docker/php/php.ini /usr/local/etc/php/php.ini
COPY docker/php/ssl/openssl.conf /etc/ssl/openssl.cnf
#RUN sed -i -e "s#TIMEZONE##g" /usr/local/etc/php/php.ini

#COPY xdebug.ini /tmp/xdebug.ini
#RUN cat /tmp/xdebug.ini >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
#RUN rm /tmp/xdebug.ini

COPY --from=composer:2.3.5 /usr/bin/composer /usr/bin/composer
# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER 1
# create composer cache directory
RUN mkdir -p /var/www/.composer && chown -R www-data /var/www/.composer

RUN usermod -u 1000 www-data

# npm & node
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash
#RUN apt-get install -y nodejs \
#  && update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10
RUN #apt install ssh -y
# build tools
RUN apt-get install -y build-essential
#RUN apt-get install -y ssh

# bugfix: remove cmdtest to install yarn correctly.
#RUN apt-get remove -y cmdtest

# yarn package manager
#RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
#  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
#RUN apt-get update && apt-get install -y yarn

RUN curl -Lsf 'https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -
ENV PATH /usr/local/go/bin:$PATH

#RUN go get github.com/mailhog/mhsendmail
#RUN cp /root/go/bin/mhsendmail /usr/bin/mhsendmail
#RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr mailhog:1025' > /usr/local/etc/php/php.ini


RUN apt-get install -y libzip-dev zip build-essential libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev  && docker-php-ext-install zip
RUN apt-get install  -y libgbm-dev gconf-service libasound2 libatk1.0-0 libatk-bridge2.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget supervisor
RUN apt-get install -y vim

RUN docker-php-ext-configure pcntl --enable-pcntl \
  && docker-php-ext-install \
    pcntl

RUN apt-get install -y nginx

COPY docker/nginx/nginx.conf /etc/nginx/conf.d

COPY docker/php/entrypoint.sh /etc/entrypoint.sh
RUN chmod +x /etc/entrypoint.sh

WORKDIR /srv
COPY ./application /srv

RUN composer install
CMD chmod -R 777 var/*

EXPOSE 80
ENTRYPOINT ["/etc/entrypoint.sh"]
