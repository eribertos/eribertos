#!/bin/bash

sudo apt install apache2 php8.1 php8.1-mysql -y
sudo apt update
sudo apt install php-mysql mysql-server-8.0 mysql-client-8.0 -y
service apache2 start && service mysql start
sudo wget -c https://wordpress.org/latest.zip -O /var/www/html/latest.zip --show-progress
sudo unzip -q /var/www/html/latest.zip -d  /var/www/html/
