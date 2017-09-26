#!/bin/bash

ADMINNAME="Sebastian Inman"
ADMINEMAIL="sebastian.inman@highwayproducts.com"

IPADDRESS=""
DOMAIN=""

Initialize() {
  # initilize the script
  UpdatePackages
  echo "fetching server IP address..."
  # fetch the server IP address
  IPADDRESS=$(curl http://icanhazip.com)
  echo "server IP address is $IPADDRESS"

  while true; do
    read -p "Install system package upgrades? [Y/N]? " PROMPT
    case $PROMPT in
      [Yy]* ) UpgradePackages;;
      [Nn]* ) InstallWebServer;;
    esac
  done
}

UpdatePackages() {
  echo "checking system for updates..."
  sudo apt update
}

UpgradePackages() {
  echo "installing system package upgrades..."
  sudo apt upgrade -y
  while true; do
    read -p "Remove unused system packages? [Y/N]? " PROMPT
    case $PROMPT in
      [Yy]* ) RemovePackages; InstallWebServer;;
      [Nn]* ) InstallWebServer;;
    esac
  done
}

RemovePackages() {
  # remove outdated packages
  sudo apt autoremove -y
}

ConfigureDomain() {
  # add domain to the hosts file
  sudo echo "$IPADDRESS $2" >> /etc/hosts
  # remove the default web directory
  sudo rm -rf /var/www/html
  # create the domain web directory
  sudo mkdir -p /var/www/$2
  # create the domain logs directory
  sudo mkdir -p /var/www/$2/logs
  # update web directory permissions
  sudo chown -R $USER:$USER /var/www/$2
  sudo chmod -R 755 /var/www
  # configure the Apache web server
  if [ $1 = "apache" ]; then ConfigureApache $1 $2; fi
  # configure the Nginx web server
  if [ $1 = "nginx" ]; then ConfigureNginx $1 $2; fi
  # install domain SSL certificate
  InstallLetsEncrypt $1 $2
}

InstallWebServer() {
  InstallPHP
  InstallMySQL
  InstallPHPMyAdmin
  PS3="Select a web server to configure: "
  select SERVER in "Apache Web Server" "Nginx Web Server" "Cancel"; do
    case "$SERVER" in
      "Apache Web Server")
        InstallApache;;
      "Nginx Web Server")
        InstallNginx;;
      "Cancel")
        break;;
    esac
  done
}

InstallApache() {
  # update packages
  UpdatePackages
  # install Apache web server
  sudo apt install apache2 -y
  # update the firewall
  sudo ufw allow "Apache Full"
  # install the Apache PHP module
  sudo apt install libapache2-mod-php7.0 -y
  while true; do
    read -p "Enter the domain for this server: " PROMPT
    ConfigureDomain "apache" $PROMPT
  done
}

InstallNginx() {
  # update packages
  UpdatePackages
  # install Nginx web server
  sudo apt install nginx -y
  # update the firewall
  sudo ufw allow "Nginx Full"
  while true; do
    read -p "Enter the domain for this server: " PROMPT
    ConfigureDomain "nginx" $PROMPT
  done
}

ConfigureApache() {
  CONFIG="
  <VirtualHost *:80>
    ServerAdmin $ADMINEMAIL
    ServerName $2
    DocumentRoot /var/www/$2
    ErrorLog /var/www/$2/logs/error.log
    CustomLog /var/www/$2/logs/access.log combined
  </VirtualHost>"
  # create the new domain Apache config
  sudo touch /etc/apache2/sites-available/$2.conf
  # write the domain Apache config file
  echo $CONFIG > /etc/apache2/sites-available/$2.conf
  # disable the default Apache config
  sudo a2dissite 000-default.conf
  # enable the new domain Apache config
  sudo a2ensite $2.conf
  # reload web server
  RestartWebServer $1
}

ConfigureNginx() {
  CONFIG="
  server {
    listen 80;
    server_name $2;
    access_log /var/www/$2/logs/access.log main;
    error_log /var/www/$2/logs/error.log info;
    root /var/www/$2/;
    index index.php;
    location ~ \.php$ {
      try_files $uri =404
      include /etc/nginx/fastcgi.conf;
      fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }
  }"
  # create the new domain Nginx config
  sudo touch /etc/nginx/sites-available/$2
  # write the domain Nginx config file
  echo $CONFIG > /etc/nginx/sites-available/$2
  # create a link to the new domain config file
  sudo ln -s /etc/nginx/sites-available/$2 /etc/nginx/sites-enabled/$2
}

InstallPHP() {
  # update packages
  UpdatePackages
  # install PHP 7.0
  sudo apt install php7.0 php7.0-fpm -y
  # install common PHP modules
  sudo apt install php-mbstring -y
  sudo apt install php-gettext -y
  # enable installed PHP modules
  sudo phpenmod mbstring
  sudo phpenmod mcrypt
}

InstallMySQL() {
  # update packages
  UpdatePackages
  # install mysql database server
  sudo apt install mysql-server -y
  # clean the mysql installation
  sudo mysql_secure_installation
}

InstallPHPMyAdmin() {
  # update packages
  UpdatePackages
  # install PHPMyAdmin
  sudo apt install phpmyadmin -y
}

InstallLetsEncrypt() {
  # add certbot repository
  sudo add-apt-repository ppa:certbot/certbot
  # update packages
  UpdatePackages
  if [ $1 = "apache" ]; then
    # install the certbot package
    sudo apt install python-certbot-apache -y
    # install ssl certificate
    sudo certbot --apache -d $2
  fi
  if [ $1 = "nginx" ]; then
    # install the certbot package
    sudo apt install python-certbot-nginx -y
    # install ssl certificate
    sudo certbot --nginx -d $2
    # update the diffie-hellman parameters
    sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    # add dhparam to the default Nginx server block configuration
    echo "ssl_dhparam /etc/ssl/certs/dhparam.pem;" >> /etc/nginx/sites-available/default
  fi
  # check the validity of the ssl certificate every day at 3:15am
  (crontab -u userhere -l; echo "15 3 * * * /usr/bin/certbot renew --quiet" ) | crontab -u userhere -
  # reload web server
  RestartWebServer $1
}

RestartWebServer() {
  echo "Restarting the web server..."
  if [ $1 = "apache" ]; then sudo systemctl restart apache2; fi
  if [ $1 = "nginx" ]; then sudo systemctl restart nginx; fi
}


Initialize
