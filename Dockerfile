# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: rhullen <rhullen@student.21-school.ru>     +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2020/07/20 18:48:15 by rhullen           #+#    #+#              #
#    Updated: 2020/07/20 20:00:38 by rhullen          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:buster
LABEL author="rhullen"
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y curl

# --- NGINX ---
RUN apt-get install -y nginx
WORKDIR /etc/nginx/sites-available/
COPY ./srcs/nginx_ai_on.conf .
RUN ln -s /etc/nginx/sites-available/nginx_ai_on.conf /etc/nginx/sites-enabled/
WORKDIR /
COPY ./srcs/nginx_ai_on.conf .
COPY ./srcs/nginx_ai_off.conf .
COPY ./srcs/autoindex_off.sh .
COPY ./srcs/autoindex_on.sh .

# --- MARIADB ---
RUN apt-get install -y mariadb-server
WORKDIR /
COPY ./srcs/create_test_db.sql .
COPY ./srcs/ft_server_db_dump.sql .
RUN service mysql start && mysql < create_test_db.sql && mysql testdb < ft_server_db_dump.sql

# --- WORDPRESS ---
RUN apt-get install -y php-fpm php-mysql
RUN apt-get install -y php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip
WORKDIR /var/www/ft_server
RUN curl -LO https://wordpress.org/latest.tar.gz
RUN tar xzf latest.tar.gz
RUN rm -rf latest.tar.gz
RUN chown -R www-data:www-data /var/www/ft_server/wordpress
WORKDIR /var/www/ft_server/wordpress
COPY ./srcs/wp-config.php .

# --- SSL ---
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=21/OU=school/CN=localhost"

# --- PHPMYADMIN ---
WORKDIR /var/www/ft_server
RUN curl -LO https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-english.tar.gz
RUN tar xzf phpMyAdmin-5.0.2-english.tar.gz
RUN mkdir phpmyadmin
RUN mv phpMyAdmin-5.0.2-english/* phpmyadmin/
RUN rm -rf phpMyAdmin-5.0.2-english phpMyAdmin-5.0.2-english.tar.gz
COPY ./srcs/config.inc.php ./phpmyadmin/

EXPOSE 80 443

WORKDIR /
COPY ./srcs/start_services.sh .
ENTRYPOINT ["bash", "start_services.sh"]
