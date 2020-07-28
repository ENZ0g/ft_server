# ft_server

Здесь я опишу основные моменты проекта, который я выполнял на Ubuntu 20.04 LTS. 
Чтобы получить больше информации, можете воспользоваться моим [списком вдохновения](#source_info).

>Узнать свой дистрибутив можно с помощью команды `lsb_release -a`

Для начала, запустим все, что требуется по заданию, локально и уже потом запакуем
все в docker image.

1. Устанавливаем LEMP
2. [Запускаем WordPress](#wordpress)
3. [Подключаем SSL](#SSL)
4. [Подключаем phpMyAdmin](#phpMyAdmin)
5. [Подключаем autoindex](#autoindex)

#### Устанавливаем LEMP

LEMP - это стек Linux, Nginx, MySQL и PHP. Linux у меня уже стоит, поэтому начнем с 
Nginx

```commandline
$ sudo apt update
$ sudo apt upgrade
$ sudo apt install nginx
```

У меня на Ubuntu по умолчанию стоит Apache2. Об этом сообщает браузер, если перейти по
 адресу `localhost`. Чтобы запустить и проверить Nginx, выполним следующие команды:
 
 ```commandline
$ sudo systemctl stop apache2
$ sudo systemctl start nginx
$ sudo systemctl status nginx
``` 

Последняя комнда выведет информацию о сервере. Если все успешно, там будет
статус `active`. Забавно, что если сейчас снова зайти на `localhost`, то мы
увидим приветствие Apache. Это происходит потому, что по-умолчанию сервером
раздаётся содержимое папки `/var/www/html` в которой и лежит `index.html` от Apache.
Можно удалить его или переместить и тогда мы увидим приветствие от Nginx.

MySQL в моей Ubuntu уже тоже есть. Проверить, есть ли у вас, можно командой:
 
 ```commandline
$ mysql
```
 
 Должна появиться информация о версии и строка приветствия для ввода SQL-команд.
  Наберите `exit;` для возврата в терминал. Если всего этого не произошло, 
  значит устанавите MySQL командой:

```commandline
$ sudo apt install mysql-server
```

>Нужно заметить, что по заданию в качестве ОС у нас должен быть дистрибутив Debian buster.
>На Debian вместо MySQL, даже введя команду выше, установится MariaDB. Поэтому, в `Dockerfile`
>мы пропишем сразу:
>
>```commandline
>$ sudo apt install mariadb-server
>``` 

Сейчас мы этого не будем делать, но в реальных проектах  для повышения уровня безопасности 
при работе с данными, рекомендуется после установки базы данны запустить скрипт:
 
 ```commandline
$ sudo mysql_secure_installation
``` 

[Подробнее про скрипт](https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-20-04#step-2-—-installing-mysql)

Теперь перейдём к PHP. В отличае от Apache, Nginx не имеет встроенного обработчика PHP.
Поэтому установим его вместе с библиотекой для работы PHP с MySQL. Сам PHP, если его 
 еще нет, установится как зависимость.

```commandline
$ sudo apt install php-fpm php-mysql
```

Теперь проверим, как всё это работает.

Переходим в `/var/www/` и создадём там директорию, например, `test-site`:

```commandline
$ sudo mkdir test-site
```

Начнем с простой статичной страницы, поэтому создадим файл `index.html` с таким содержижим:

```html
<h1>Hello world!!</h1>
```

Теперь заставим Nginx раздавать этот файл при посещении `localhost`. Для этого переходим в 
`/etc/nginx/sites-available` и создадим там файл `test-site` с таким содержимым:

```
server {
    listen 80;
    server_name localhost;
    root /var/www/test-site;
    index index.html;
}
```

Т.е. мы указали, что для запроса на `localhost` по `80` порту использовать содержимое директории 
`/var/www/test-site` и в качестве базовой страницы отдать `index.html`.
На самом деле, порт `80` используется по умолчанию и `index.html` отдается тоже по умолчанию 
(если он есть). Поэтому, эти директивы в нашем случае можно опустить и все продолжит работать:

```
server {
    server_name localhost;
    root /var/www/test-site;
}
``` 

Все что осталось сделать, в директории `/etc/nginx/sites-enabled` прописать такой же файл.
Мы просто сделаем сылку на исходный:

```commandline
$ sudo ln -s /etc/nginx/sites-available/test-site /etc/nginx/sites-enabled/
```

>Убедитесь, что используете абсолютные пути. Иначе можно получить ошибку 
>`40: Too many levels of symbolic links`

Перезапустим сервер (это нужно делать после каждого изменения в конфигурационном файле):

```commandline
$ sudo nginx -s reload
```

Проверяем, что браузер по адресу `localhost` отдает нам `Hello world!!`.

Теперь, подключим PHP, будем отображать динамическую страницу, например текущюю дату и время.
Для этого изменим наш конфигурационный файл:

```
server {
    server_name localhost;
    root /var/www/test-site;
    index time.php;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
}
```

`index` - теперь в качестве исходной страницы будет отдаваться `time.php`

`location` - такой директивой задаются обработчики путей. В нашем случае регулярное выражение
 (они начинаются с ~) говорит, что все файлы с расширением `.php` обрабатываются этой директивой.
 В ней мы указали конфигурацию обработчика и путь по которому его можно найти (эти файлы созданы 
 автоматически).

Добавим `time.php` в `/var/www/test-site`. Вот его содержимое:

```php
<?php
echo date("Y-m-d H:i:s");
?>
```

После перезапуска сервера, проверьте, что по запросу `localhost` отображается дата и время.

#### <a id='#SSL'></a>Wordpress

Скачиваем архив последней версии с официального сайта:

```commandline
$ curl -LO https://wordpress.org/latest.tar.gz
```

`-L` - Follow redirects if the server reports that the requested page has moved.\
`-O` - Назвать файл так, как он называется при скачивании (последняя часть uri, в нашем случае `latest.tar.gz`), 
и сохранить в текущей директории. Я выполнил эту команду в `/var/www/`.

Чтобы распаковать архив:

```commandline
$ sudo tar xzvf latest.tar.gz
```

Эта команда создаст директорию `/var/www/wordpress` и положит туда все файлы. Nginx при обслуживании нашего
сайта будет читать и изменять эти файлы. Происходить это будет от имени пользователя `www-data`, поэтому 
необходимо дать право этому пользователю выполнять эти действия:

```commandline
$ sudo chown -R www-data:www-data /var/www/wordpress
```

Мы сказали что всё содержимое (`-R` - recursive, т.е. и вложенные папки, и скрыте файлы) директории 
`/var/www/wordpress` передать пользователю и группе `www-data`.

Вот обновленный `etc/nginx/sites-available/test-site` (новые `root` и `index`):

```
server {
    server_name localhost;
    root /var/www/wordpress;
    index index.php;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
}
```

Можно перезапустить сервер и проверить в браузере `localhost`, картинка поменяется, но для работы
wordpress необходимо еще создать базу данных и изменить несколько настроек. 

Создадим базу данных. Вот список sql-команд:

```
CREATE DATABASE testdb DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'testuser'@'localhost' IDENTIFIED BY 'test_password';
GRANT ALL ON testdb.* TO 'testuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

Эти команды можно ввести по отдельности через терминал mysql (`$ sudo mysql`) или сохранить их в 
отдельном файлике (например `create_test_db.sql`) и сделать так:

```commandline
$ sudo mysql < create_test_db.sql
```

Информацию о базе данных необходимо добавить в конфигурационный файл wordpress. Сейчас в `/var/www/wordpress` 
есть `wp-config-sample.php`. Это образец конфигурационного файла. Копируем его и называем `wp-config.php`.
Конфигурационный файл именно с таким именем будет искать wordpress.

```commandline
$ sudo cp wp-config-sample.php wp-config.php
```

Открываем `wp-config.php` и вместо шаблонов ставим наши параметры:

```
define( 'DB_NAME', 'testdb');
define( 'DB_USER', 'testuser');
define( 'DB_PASSWORD', 'test_password');
define( 'DB_HOST', 'localhost');
define( 'DB_CHARSET', 'utf8mb4');
define( 'DB_COLLATE', 'utf8mb4_unicode_ci');
```

Чуть ниже в этом же конфигурационном файле есть блок *Authentication Unique Keys and Salts.* 
Проще всего его заполнить с помощью генератора, который предоставляет сам wordpress:

```commandline
$ curl -s https://api.wordpress.org/secret-key/1.1/salt/
```

`-s` - silen mode, выводить только результат запроса, без сопроводительных сообщений

В терменале появятся сразу отформатированные строчки с ключами, скопируйте и земените
аналогичный блок в `wp-config.php`.

Остался последний шаг - установить дополнительные PHP-расширения, необходимые для 
работы wordpress:

```commandline
$ sudo apt install php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip
```

Теперь можно заходить на `localhost`, где нужно будет завершить настройки уже в веб-интерфейсе.

#### <a id='#SSL'></a>Добавляем SSL

Генерируем сертификат и ключ:

```commandline
$ sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=RU/ST=Moscow/L=Moscow/O=21/OU=school/CN=localhost"
```

`req` - дополнительная команда, которая говорит, что нам нужно получить сертификат с указанными далее 
параметрами\
`-x509` -  X.509 - стандарт SSL, TLS по управлению ключами и сертификатами\
`-nodes` - отключаем защиту сертификата кодовой фразой; избавлят от необходимости вводить
её после каждого перезапуска сервера\
`-days 365` - срок действия сертификата, 365 дней\
`-newkey rsa:2048` - генерируем ключ по алгоритму RSA длиной 2048бит\
`-keyout` - место, куда сохранить ключ\
`-out` - место, куда сохранить сертификат\
`-subj` - эта опция позволяет заполнить опросник для заполнения сертификата сразу в командной строке. 
Это понадобится при составлении `Dockerfile`, если вы выполняете команду локльно
чтобы потестить, можете опустить эту опцию и заполнить опросник во время выполнения 
команды.

|||||
|---|-------|------|---|
|C|Country Name (2 letter code)|Страна|RU
|ST|State or Province Name (full name)|Область|Moscow
|L|Locality Name (eg, city)|Город|Moscow
|O|Organization Name (eg, company)|Организация|21
|OU|Organizational Unit Name (eg, section)|Подразделение|school
|CN|Common Name (e.g. server FQDN or YOUR name)|Имя, или доменное имя, или IP|localhost

Добавим сертификат, ключ и редирект с 80 на 443 порт в настройки Nginx (`/etc/nginx/sites-available/test-site`):

```
server {
    server_name localhost 127.0.0.1;
    return 308 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    root /var/www/wordpress_test;
    index index.php;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
}
```

Теперь, `localhost` доступен через https, правда, браузеры всё равно будут ругаться не доверяя
 самоподписанному сертификату.

#### <a id='#phpMyAdmin'></a>PhpMyAdmin

PhpMyAdmin - веб интерфейс для работы с базой данных. Все, что нужно сделать - скачать архив 
с приложением и сделать несколько настроек.

Скачиваем с официального [сайта](https://www.phpmyadmin.net/downloads/), 
где необходимо выбрать нужную версию. Я выбрал такую:

```commandline
$  сurl -LO https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-english.tar.gz
```

Команда скачивает архив, называет его как последняя часть uri и сохраняет в месте вызова команды,
 в моём случае это `/var/www/`.
 
Чтобы у нас одновременно был доступен и wordpress, и phpMyAdmin можно поступить несколькими 
способами:
1. В рамках текущей конфигурации nginx, положить phpMyAdmin в `/var/www/wordpress_test/` и 
тогда он будет доступен по адресу `localhost/phpmyadmin/`
2. Настроить nginx так, чтобы при обращении на `localhost/phpmyadmin/` обрабатывалась 
директория `/var/www/phpmyadmin`
3. Вариант, который я сейчас реализую. 

*Возможны ещё комбинации*

Итак переорганизуем немного директории: создадим `/var/www/ft_server` в которую переместим 
`/var/www/wordpress_test`, потом создадим `/var/www/ft_server/phpmyadmin` в которую положим
содержимое скачаного архива phpMyAdmin:

```commandline
$ sudo mkdir ft_server
$ sudo mv wordpress_test ft_server/
$ sudo mkdir ft_server/phpmyadmin
$ sudo tar xzvf phpMyAdmin-5.0.2-english.tar.gz
$ sudo mv phpMyAdmin-5.0.2-english/* ft_server/phpmyadmin
```

Обновим конфигурацию nginx (`root`):

```
server {
    server_name localhost 127.0.0.1;
    return 308 https://$server_name$request_uri;
    }

server {
    listen 443 ssl;
    root /var/www/ft_server;
    index index.php;

     ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
     ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

     location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
     }
}
```

И финальное: настройки phpMyAdmin. По аналогии с wordpress находим шаблон настроек phpMyAdmin, 
копируем и переименовываем его:
 
```commandline
$ cd phpmyadmin
$ sudo cp config.sample.inc.php config.inc.php
```

Добавляем любые 32 символа в секретный ключ для шифрования паролей, запрещаем пользователей
без паролей и с root правами.

```
$cfg['blowfish_secret'] = ')(oIkjHY^%43@#$#@!1qaswEDFtr$%gb';
$cfg['Servers'][$i]['AllowNoPassword'] = true;
$cfg['Servers'][$i]['AllowRoot'] = false;
```

Перезапускайте nginx и можно проверять `localhost/wordpress_test/` и `localhost/phpmyadmin/`.

>Напомню, user: testuser, password: test_password

>Если у вас, как и у меня сломался wordpress (потерялись css), то зайдите на `localhost/phpmyadmin/`,
>слева в дереве нажмите плюс рядом с `testdb` и выберите `wp_options`. Две первые строчки 
>`siteurl` и `home` обновите на `http://localhost/wordpress_test` (с помощью кнопки edit)

#### <a id='#phpMyAdmin'></a>Autoindex

При включеном autoindex, nginx при невозможности найти в сопоставленной запросу директории 
`index.html` или того, что указано в директиве `index` в обработчике этого запроса, отображает 
сожержимое этой директории.

Простыми словами: у нас сейчас при обращении к `localhost/` выдается 403 Forbiden, потому что
в `/var/www/ft_server/` нет `index.html`и никаких указаний, чем его заменить.

Если сейчас добавить `autoindex on` в обработчик такого пути, будет отображаться содержимое
`ft_server`:

```
server {
    server_name localhost 127.0.0.1;
    return 308 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    root /var/www/ft_server;
    index index.php;

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    autoindex on;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
}
```  

Перезагружаем nginx и пробуем.

<a id='#source_info'></a>Основными источниками информации при выполнении этого проекта были:
1. [Статья по установке LEMP на Ubuntu](https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-20-04)
2. [Статья по установке LEMP на Debian](https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mariadb-php-lemp-stack-on-debian-10)
3. [Статья по запуску Wordpress на LEMP](https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-lemp-nginx-mariadb-and-php-on-debian-10)
4. [Статья по Self-Signed SSL](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-on-debian-10)
5. [Статья по phpMyAdmin](https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-phpmyadmin-with-nginx-on-an-ubuntu-18-04-server)
6. [Документация Docker](https://docs.docker.com/engine/)
7. [Документация Nginx](https://nginx.org/ru/docs/)
8. [google](https://www.google.com/)