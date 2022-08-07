#Сборка Nginx+php-fpm+redis+bitrix-push-server

Предназначена для локальной разработки. 
Перед сборкой локально почистить кеш, локально установить composer зависимости.
Рекомендуется перезапустить контейнер после сборки, если будут наблюдаться проблемы с пуш сервером.

#структура проекта 
    - bx_push/
        -- etc/
        -- entrypoint.sh
        -- init_script.php
    - mysql/
    - upload/
    - www/
    - .gitignore
    - docker-compose.yml
    - Dockerfile
    - README.md

bx_push содержит конфиги для сервисов
init_script.php - выполняется в entrypoint.sh - прописывает ключ пуш сервера в базу
mysql - файлы базы
upload - папка со статикой для монтирования в контейнер
www - ядро битрикса + кодовая база проекта без папки upload
        
#Не обязательно
Перегенерировать конфиги ssh для контейнера ssh_host_rsa_key и ssh_host_rsa_key.pub 
Сейчас они лежат в /etc/ssh и копируются в контейнер при сборке

    ssh-keygen -t rsa -f ssh_host_rsa_key
    ssh-keygen -t ecdsa -f ssh_host_ecdsa_key
    ssh-keygen -t ed25519 -f ssh_host_ed25519_key

#ВАЖНО!!!
Сборка предназначена только для локальной разработки. Для прод сборки необходима доработка конфигов, 
разделение прав пользователей, разделение сервисов на отдельные контейнеры.

#Настройка phpStorm для дебага

для настройки File -> Settings -> Build, Execution, Deployment -> Docker
у меня выбран пункт Docker for Windows 
и в настройках докера не активна галочка "Expose daemon on tcp:.."
Остальное можно посмотреть по видео

https://www.youtube.com/watch?v=XszBIW4sPHk