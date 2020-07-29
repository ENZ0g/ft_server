#!/bin/bash

rm -f /etc/nginx/sites-available/nginx_ai_off.conf
rm -f /etc/nginx/sites-enabled/nginx_ai_off.conf
cp /nginx_ai_on.conf /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/nginx_ai_on.conf /etc/nginx/sites-enabled/
service nginx restart