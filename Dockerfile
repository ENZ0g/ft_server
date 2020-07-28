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

WORKDIR /ft_server

RUN apt update
RUN apt install nginx
RUN apt install mariadb-server
RUN apt install php-fpm php-mysql

