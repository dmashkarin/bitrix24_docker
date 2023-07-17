FROM redhat/ubi8:8.5
RUN set -eux \
    && rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    && dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm \
    && dnf module enable php:remi-7.3 -y \
    && dnf install -y php php-cli php-common php-json php-iconv procps
RUN set -eux \
    && yum update -y \
    && yum install -y wget python3 npm \
        nano \
        sudo \
        cronie \
        openssh \
        curl-devel \
        expat-devel \
        openssl-devel \
        zlib-devel \
        pcre-devel \
        bind-utils \
        nginx \
    && dnf module reset redis -y \
    && dnf --enablerepo=remi-modular-test module enable redis:remi-6.0 -y\
    && dnf --enablerepo=remi-modular-test module install redis:remi-6.0 -y \
    && yum install -y supervisor \
    && yum clean -y all \
    && dnf install -y php-intl \
    php-ftp \
    php-xdebug \
    php-mcrypt \
    php-mbstring \
    php-soap \
    php-gmp \
    php-pdo_odbc \
    php-dom \
    php-pdo \
    php-zip \
    php-mysqli \
    php-bcmath \
    php-gd \
    php-odbc \
    php-pdo_mysql \
    php-gettext \
    php-xmlreader \
    php-xmlwriter \
    php-tokenizer \
    php-xmlrpc \
    php-bz2 \
    php-curl \
    php-ctype \
    php-session \
    php-exif \
    php-opcache \
    php-ldap \
#    esmtp \
    && mkdir /run/php-fpm/ \
    && rm -rf /var/cache/yum/* \
    && ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime

WORKDIR /opt
ARG HOSTUID

RUN set -eux \
    && BUILD_PACKAGE="wget make gcc gcc-c++ checkpolicy policycoreutils" \
    && yum install -y $BUILD_PACKAGE \
    && useradd -m -u $HOSTUID bitrix\
    && usermod -g bitrix redis \
    && chown redis:redis /var/log/redis/ \
    && echo -e '[Service]\nGroup=bitrix' > /etc/systemd/system/redis.service.d/custom.conf \
    && wget https://repos.1c-bitrix.ru/vm/push-server-0.2.2.tgz \
    && npm install --production ./push-server-0.2.2.tgz \
    && rm -f push-server-0.2.2.tgz bitrix-push-server \
    && cd /opt/node_modules/push-server \
    && cp -R ./etc/init.d/* /etc/init.d/ \
    && cp -R ./etc/push-server/ /etc/ \
    && cp -R ./etc/sysconfig/* /etc/sysconfig/ \
    && chmod 440 /etc/sysconfig/push-server-multi \
    && chown bitrix:root /etc/sysconfig/push-server-multi \
    && ln -sf /opt/node_modules/push-server/logs /var/log/push-server \
    && ln -sf /opt/node_modules/push-server/etc/push-server /etc/push-server \
    && ln -sf /opt/node_modules/push-server /opt/push-server \
    && echo 'd /tmp/push-server 0770 bitrix bitrix -' > /etc/tmpfiles.d/push-server.conf \
    && systemd-tmpfiles --remove --create \
    && usermod -aG wheel bitrix \
    && chown bitrix:root /opt/node_modules/push-server/logs \
    && cd /opt/push-server \
    && npm install \
    && chown -R bitrix:bitrix /opt/push-server \
    && ln -sf /opt/data /opt/node_modules/push-server/data \
    && usermod -aG bitrix nginx \
    && mkdir -p /home/bitrix \
    && chown bitrix:bitrix /home/bitrix/ \
    && mkdir -p /home/bitrix/tmp \
    && chmod 770 /home/bitrix/tmp \
    && chown bitrix:bitrix /home/bitrix/tmp \
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
    && echo '* * * * * /home/bitrix/www/bitrix/modules/main/tools/cron_events.php && date >> /var/log/bitrix_cron.log' > /var/spool/cron/bitrix \
    && yum remove -y $BUILD_PACKAGE \
    && rm -rf /var/cache/yum/* \
    && dnf install -y postfix cyrus-sasl-plain git openssh-server


COPY --chown=bitrix:bitrix ./cp_core /home/bitrix/cp_core
COPY --chown=bitrix:bitrix ./www /home/bitrix/www
COPY --chown=bitrix:bitrix ./calltouch /home/bitrix/calltouch
COPY --chown=bitrix:bitrix ./symlink_update.sh /home/bitrix
COPY --chown=bitrix:bitrix ./symlink_update_calltouch.sh /home/bitrix

COPY ./bx_push/etc /etc
COPY ./bx_push/init_script.php /home/bitrix/init_script.php
COPY ./bx_push/entrypoint.sh /entrypoint.sh

#RUN chown mail:mail /var/spool/mail/

RUN cd /home/bitrix/www \
    && npm install \
    && chown postfix: /usr/sbin/postfix \
    && chown bitrix: /etc/sysconfig/push-server-multi \
    && tr -d '\r' < /etc/init.d/push-server-multi > /etc/init.d/push-server-multi \
    && /etc/init.d/push-server-multi configs pub \
    && /etc/init.d/push-server-multi configs sub \
    && chmod +x /entrypoint.sh \
    && chmod +x /home/bitrix/init_script.php \
    && chmod +x /var/spool/cron/bitrix \
    && rm -f /run/nologin \
    && cd /etc/ssh \
    && ssh-keygen -q -t rsa -N '' -f ssh_host_rsa_key \
    && chmod 400 ssh_host_rsa_key \
    && ln -s /home/bitrix/cp_core/bitrix /home/bitrix/www/bitrix \
    && ln -s /home/bitrix/cp_core/bitrix /home/bitrix/calltouch/bitrix \
    && ln -s /home/bitrix/www/upload /home/bitrix/calltouch/upload \
    && chown bitrix: /home/bitrix/www/bitrix \
    && chown bitrix: /home/bitrix/calltouch/bitrix \
    && chown bitrix: /home/bitrix/calltouch/upload

RUN cd /home/bitrix \
    && ./symlink_update.sh \
    && ./symlink_update_calltouch.sh \
    && cd /home/bitrix/www/deploy \
    && ./create_links.sh




#RUN chmod 755 `find /home/bitrix/www -type d` \
#    && chmod 644 `find /home/bitrix/www -type f`


EXPOSE 80
EXPOSE 443

WORKDIR /home/bitrix/www/

ENTRYPOINT /entrypoint.sh