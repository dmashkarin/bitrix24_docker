#!/bin/bash
#Для запуска на linux системах необходимо решить конфликт доступа к файлам, которые подключаются в контейнер через volume
#Для этого подменяется id пользователя bitrix внутри контейнера на id внешнего владельца файлов
# >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >  >

#docker entrypoint script
#for sync uid:gid host<->container

#usage
#add to build script ENV USER, ENV GROUP point to user from who start app in container
#docker run -e "HOSTUID=`id -u USERNAME`" -e "HOSTGID=`id -g GROUP`" where user and group its host user:group
default() {
  set -e
  changeFlag=0

  # allow the container to be started with `--user`
  if [ "$(id -u)" = '0' ]; then

      #change container  UID:GID to HOST UID:GID
      #to save right permissions

      test -z $HOSTUID && { echo -e "set HOSTUID ENV var, script not work properly \nEXIT"; exit 1; }
      test -z $HOSTGID && { echo -e "set HOSTGID ENV var, script not work properly \nEXIT"; exit 1; }
      id -u $USER &> /dev/null || { echo -e "user $USER not exist in container, script not work properly \nEXIT"; exit 1; }
      id -g $GROUP &> /dev/null || { echo -e "group $GROUP not exist in container, script not work properly \nEXIT"; exit 1; }

      if [ $HOSTUID -ne `id -u $USER` ]; then
          usermod -o -u $HOSTUID $USER
          echo -e "set $USER -uid-> $HOSTUID"
          changeFlag=$((changeFlag+1))
      fi

      if [ $HOSTGID -ne `id -g $GROUP` ]; then
          groupmod -o -g $HOSTGID $GROUP
          echo -e "set $GROUP -gid-> $HOSTGID"
          changeFlag=$((changeFlag+1))
      fi

      test $changeFlag -eq 0 && echo -e "nothing to be done \n$USER=`id -u $USER` $GROUP=`id -g $GROUP`"

  #    exec gosu $USER "$0" "$@"
      return 0
  fi
  echo "0 = $0  @ = $@"
  exec "$0" "$@"

  return 0
}

#default

chown bitrix:redis /var/log/redis/
chown bitrix:bitrix_releaser /etc/sysconfig/push-server-multi
chown bitrix:bitrix_releaser /opt/node_modules/push-server/logs
chown -R bitrix:bitrix_releaser /opt/push-server
chown bitrix:bitrix_releaser /home/bitrix/
chown bitrix:bitrix_releaser /home/bitrix/tmp
chown bitrix:bitrix_releaser /etc/sysconfig/push-server-multi
chown bitrix:bitrix_releaser /tmp/push-server
chmod 755 /home/bitrix/
chmod 400 /home/bitrix/.ssh/id_rsa
chmod 600 /home/bitrix/.ssh/id_rsa.pub
chown bitrix:bitrix_releaser /home/bitrix/.ssh/id_rsa
chown bitrix:bitrix_releaser /home/bitrix/.ssh/id_rsa.pub
chmod 644 /etc/ssh/ssh_host_dsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_rsa_key.pub
chmod 600 /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_rsa_key
cat /home/bitrix/.ssh/id_rsa.pub > /home/bitrix/.ssh/authorized_keys
chown bitrix:bitrix_releaser /home/bitrix/.ssh/authorized_keys
chmod 600 /home/bitrix/.ssh/authorized_keys


#rm -rf /home/bitrix/www/bitrix/cache
#rm -rf /home/bitrix/www/bitrix/managed_cache

#<   <   <   <   <   <   <   <   <   <   <   <   <   <   <   <   <   <   <   <   <   <   <
echo 'start CORP'
#задержка, что бы успел подняться стартануть mysql - у меня по логам около 4 секунд инициализируется mysql
sleep 8
PUSH_SERVER_SECURITY_KEY=$(cat /etc/sysconfig/push-server-multi | grep KEY | cut -c14-30)
echo "TRY TO CHANGE PUSH_SERVER_KEY=$PUSH_SERVER_SECURITY_KEY.."
php -d mbstring.func_overload=0 -d opcache.enable_cli=0 -d opcache.enable=0 /home/bitrix/init_script.php

echo "START REDIS"
service redis-server start
echo "START PHP"
service php8.1-fpm start
echo "START NGINX"
nginx -g 'daemon off;'

#supervisord -n -c /etc/supervisord.conf

#echo "git pull/checkout"
#git checkout release
#git fetch --all
#git pull