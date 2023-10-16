FROM debian:bullseye-slim
ARG HOSTUID
ARG HOSTGID

ENV NGINX_VERSION   1.22.1

RUN set -eux \
    && useradd -m -u $HOSTUID bitrix \
    && groupadd -g $HOSTGID bitrix_releaser \
    && usermod -g bitrix_releaser bitrix \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        python3 \
        gcc \
        make \
        npm \
        curl \
        ca-certificates \
        openssh-server \
        expat \
        gettext \
        tar \
        wget \
        git \
        bzip2 \
        libpcre3 \
        libpcre3-dev \
        zlib1g \
        zlib1g-dev \
        lsb-release \
        apt-transport-https

WORKDIR /opt/
COPY --chown=bitrix:bitrix_releaser ./install/nginx-${NGINX_VERSION} /opt/nginx-${NGINX_VERSION}
COPY --chown=bitrix:bitrix_releaser ./install/headers-more-nginx-module-0.33 /opt/headers-more-nginx-module-0.33


RUN cd nginx-${NGINX_VERSION} \
    && chmod +x configure \
    && CC=/etc/alternatives/cc ./configure --sbin-path=/usr/bin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid \
     --add-module=../headers-more-nginx-module-0.33 --with-http_gzip_static_module \
     --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_v2_module \
    && make \
    && make install \
    && cd /run \
    && mkdir -m=755 php-fpm \
    && mkdir "/var/log/nginx/"

RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' \
    && apt update \
    && apt install php8.1-cli php8.1-fpm -y \
    && apt install php8.1-apcu \
      php8.1-bcmath \
      php8.1-gd \
      php8.1-gmp \
      php8.1-imap \
      php8.1-ldap \
      php8.1-memcache \
      php8.1-mcrypt \
      php8.1-mysqli \
      php8.1-mysqlnd \
      php8.1-pdo \
      php8.1-posix \
      php8.1-pspell \
      php8.1-readline \
      php8.1-shmop \
      php8.1-shmop \
      php8.1-soap \
      php8.1-sqlite3 \
      php8.1-sysvmsg \
      php8.1-sysvsem \
      php8.1-sysvshm \
      php8.1-tidy \
      php8.1-xmlrpc \
      php8.1-xdebug \
      php8.1-zip -y \
      php8.1-mysql \
      php8.1-sqlite3 \
      php-xml \
      php8.1-opcache \
      php-geoip


ENV NVM_DIR /usr/local/nvm
ENV NODE_MAJOR 18

RUN apt-get update \
    && apt-get install -y gnupg \
    && mkdir -p /etc/apt/keyrings/ \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install nodejs -y

WORKDIR /opt

RUN set -eux \
#    && BUILD_PACKAGE="wget make gcc gcc-c++ checkpolicy policycoreutils" \
    && BUILD_PACKAGE="wget make gcc g++ checkpolicy policycoreutils" \
    && apt-get install -y redis sudo nano cron $BUILD_PACKAGE \
    && usermod -g bitrix_releaser redis \
    && chown redis:bitrix_releaser /var/log/redis/ \
    && sed -i -e 's/Group=redis/Group=bitrix_releaser/g' /lib/systemd/system/redis-server.service \
#    && echo -e '[Service]\nGroup=bitrix' > /etc/systemd/system/redis.service.d/custom.conf \
#    && wget https://repos.1c-bitrix.ru/vm/push-server-0.2.2.tgz \
    && wget https://repos.1c-bitrix.ru/vm/push-server-0.3.0.tgz \
    && npm install --production ./push-server-0.3.0.tgz \
    && rm -f push-server-0.3.0.tgz bitrix-push-server \
    && cd /opt/node_modules/push-server \
    && cp -R ./etc/init.d/* /etc/init.d/ \
    && cp -R ./etc/push-server/ /etc/ \
    && cp -R ./etc/sysconfig /etc/sysconfig \
    && chmod 440 /etc/sysconfig/push-server-multi \
    && chown bitrix:bitrix_releaser /etc/sysconfig/push-server-multi \
    && ln -sf /opt/node_modules/push-server/logs /var/log/push-server \
    && ln -sf /opt/node_modules/push-server/etc/push-server /etc/push-server \
    && ln -sf /opt/node_modules/push-server /opt/push-server \
    && echo 'd /tmp/push-server 0770 bitrix bitrix_releaser -' > /etc/tmpfiles.d/push-server.conf \
    && systemd-tmpfiles --remove --create \
    && usermod -aG sudo bitrix \
    && chown bitrix:bitrix_releaser /opt/node_modules/push-server/logs \
    && cd /opt/push-server \
    && npm install \
    && chown -R bitrix:bitrix_releaser /opt/push-server \
    && ln -sf /opt/data /opt/node_modules/push-server/data \
#    && usermod -aG bitrix nginx \
    && mkdir -p /home/bitrix \
    && chown bitrix:bitrix_releaser /home/bitrix/ \
    && mkdir -p /home/bitrix/tmp \
    && chmod 770 /home/bitrix/tmp \
    && chown bitrix:bitrix_releaser /home/bitrix/tmp \
#catdoc нужен для поиска по содержимому документов
    && cd /tmp \
    && wget http://ftp.wagner.pp.ru/pub/catdoc/catdoc-0.95.tar.gz \
    && tar -xzf catdoc-0.95.tar.gz \
    && cd catdoc-0.95 \
    && ./configure \
    && make \
    && make install \
    && rm -rf /tmp/catdoc-0.95 \
    && rm /tmp/catdoc-0.95.tar.gz \
    && mkdir -p /var/spool/cron/ \
    && echo '* * * * * /home/bitrix/www/bitrix/modules/main/tools/cron_events.php && date >> /var/log/bitrix_cron.log' > /var/spool/cron/crontabs/bitrix \
    && apt-get remove -y $BUILD_PACKAGE

#RUN apt-get install -y postfix git openssh-server
#    cyrus-sasl-plain



#COPY --chown=bitrix:bitrix_releaser ./web /home/bitrix/web

RUN set -eux \
    && cd /home/bitrix \
    && chmod 771 tmp
#    && chown -R bitrix:bitrix_releaser /home/bitrix \
#    && rm -rf /opt/* \
#    && mkdir "/opt/webdir" && mkdir "/opt/webdir/logs/" && chown bitrix:bitrix_releaser /opt/webdir/logs/ && chmod 771 /opt/webdir/logs/
#    && echo '* * * * * /home/bitrix/www/bitrix/modules/main/tools/cron_events.php && date >> /var/log/bitrix_cron.log' > /var/spool/cron/bitrix
#
##COPY ./etc /etc
##COPY ./nginx /etc/nginx --exclude=php74
##COPY ./nginx/php74 /etc/php-fpm/
#
##RUN #mkdir -p "/etc/nginx/ssl" \
##  && openssl req -x509 -nodes -days 365 -subj /CN=Barrier -newkey rsa:2048 -keyout /etc/nginx/ssl/pool_manager.key -out /etc/nginx/ssl/pool_manager.pem \
##  && openssl req -x509 -nodes -days 365 -subj /CN=Barrier -newkey rsa:2048 -keyout /etc/nginx/ssl/web/localhost.key -out /etc/nginx/ssl/web/localhost.pem \
##  && openssl req -x509 -nodes -days 365 -subj /CN=Barrier -newkey rsa:2048 -keyout /home/bitrix/conf/web/ssl.mango-loyalty.ru.key -out /home/bitrix/conf/web/ssl.mango-loyalty.ru.pem \
##  && openssl req -x509 -nodes -days 365 -subj /CN=Barrier -newkey rsa:2048 -keyout /home/bitrix/conf/web/ssl.mango-office.ru.key -out /home/bitrix/conf/web/ssl.mango-office.ru.pem \
##  && openssl req -x509 -nodes -days 365 -subj /CN=Barrier -newkey rsa:2048 -keyout /etc/nginx/ssl/cert.pem -out /etc/nginx/ssl/cert.pem
##  && openssl x509 -fingerprint -sha1 -noout -in /etc/nginx/ssl/pool_manager.pem > /etc/nginx/ssl/Fingerprints/Local.txt
#

COPY --chown=bitrix:bitrix_releaser ./bx_push/entrypoint.sh /entrypoint.sh
COPY --chown=bitrix:bitrix_releaser ./bx_push/init_script.php /home/bitrix/init_script.php
COPY ./bx_push/lib/systemd/system/redis-server.service /lib/systemd/system/redis-server.service
COPY ./bx_push/lib/systemd/system/php8.1-fpm.service /lib/systemd/system/php8.1-fpm.service

RUN chmod +x /entrypoint.sh

EXPOSE 80
EXPOSE 443

WORKDIR /home/bitrix/www/

ENTRYPOINT /entrypoint.sh