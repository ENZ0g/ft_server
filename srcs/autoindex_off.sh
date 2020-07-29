#!/bin/bash

rm -f /etc/nginx/sites-available/nginx_ai_on.conf
rm -f /etc/nginx/sites-enabled/nginx_ai_on.conf
cp /nginx_ai_off.conf /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/nginx_ai_off.conf /etc/nginx/sites-enabled/
service nginx restart
