#!/bin/bash

# Set script directory
SCRIPT_FILE=$(readlink -f "$0")
SCRIPT_FOLDER=$(dirname "$SCRIPT_FILE")

# Import config file settings
source $SCRIPT_FOLDER/config

# Make random user and MySQL passwords
USER_PASSWORD=$(openssl rand -base64 12)
MYSQL_PASSWORD=$(openssl rand -base64 12)

# Fetch IP address and local time
IP_ADDRESS=$(curl http://icanhazip.com)
CURRENT_DATE=`date '+%Y-%m-%d %H:%M:%S'`

PromptSettings() {
  # Prompt user for their full name
  echo ""
  read -p "Enter your full name: " PROMPT_REAL_NAME
  REAL_NAME=$PROMPT_REAL_NAME
  # Prompt user for their system username
  echo ""
  read -p "Enter your username: " PROMPT_USERNAME
  USERNAME=$PROMPT_USERNAME
  # Prompt user for their email address
  echo ""
  read -p "Enter your email address: " PROMPT_EMAIL
  USER_EMAIL=$PROMPT_EMAIL
  # Prompt user for their password
  if [[ SECURE_INSTALL = "false" ]]; then
    echo ""
    read -p "Enter your password: " PROMPT_PASSWORD
    USER_PASSWORD=$PROMPT_PASSWORD
    MYSQL_PASSWORD=$USER_PASSWORD
  fi
  # Prompt user for the servers domain name
  echo ""
  read -p "Enter the domain for this server (leave empty to use server IP): " PROMPT_DOMAIN
  echo ""
  if [[ -n "$PROMPT_DOMAIN" ]]; then
    ISSET_DOMAIN="true"
    SITE_DOMAIN=$PROMPT_DOMAIN
    DATABASE="${SITE_DOMAIN//.}"
    SERVER_NAMES="$IPADDRESS $SITE_DOMAIN www.$SITE_DOMAIN"
  else
    ISSET_DOMAIN="false"
    SITE_DOMAIN=$IP_ADDRESS
    DATABASE="wordpress"
    SERVER_NAMES="$IP_ADDRESS"
  fi
  # Add the new user to the system
  AddSystemUser
}


AddSystemUser() {
  sudo adduser $USERNAME --gecos "$REAL_NAME,,," --disabled-password
  echo "$USERNAME:$USER_PASSWORD" | sudo chpasswd
  sudo usermod -aG sudo $USERNAME
  sudo mkdir -p /home/$USERNAME
  sudo chown -R $USERNAME:$USERNAME /home/$USERNAME
}


UpdatePackages() {
  sudo apt update
}


InstallUpdates() {
  sudo apt upgrade -y
}


ConfigureSystem() {
  # Update the servers hostname to match the domain
  echo $SITE_DOMAIN > /etc/hostname
  hostname -F /etc/hostname
  # Set the servers local timezone to PST
  echo "America/Los_Angeles" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
  # Update the current time variable
  CURRENT_DATE=`date '+%Y-%m-%d %H:%M:%S'`
  # Check for package updates
  UpdatePackages
  # Install package updates
  InstallUpdates
  # Remove old packages
  sudo apt autoremove -y
  # Install system dependencies
  InstallDependencies
  # Configure the firewall
  ConfigureFirewall
  # Start the Fail2Ban service
  sudo service fail2ban start
  # Install and configure PHP
  InstallPHP
  # Install and configure Nginx
  InstallNginx
  # Install and configure MySQL
  InstallMySQL
}


InstallDependencies() {
  # Install the UFW package
  sudo apt install ufw -y
  # Install the unzip package
  sudo apt install unzip -y
  # Install the Fail2Ban package
  sudo apt install fail2ban -y
  # Install the libpcre3 package
  sudo apt install libpcre3 -y
  # Install the LetsEncrypt package
  sudo apt install letsencrypt -y
  # Install Redis cache packages
  sudo apt install redis-server -y
}


ConfigureFirewall() {
  # Allow SSH through firewall
  sudo ufw allow ssh
  # Allow HTTP through firewall
  sudo ufw allow http
  # Allow HTTPS through firewall
  sudo ufw allow https
  # Enable the firewall
  echo "Y" | sudo ufw enable
}


InstallPHP() {
  # Download the most recent PHP repository
  sudo add-apt-repository ppa:ondrej/php -y
  # Check for package updates
  UpdatePackages
  # Install PHP and common modules
  sudo apt install php7.1-fpm php7.1-common php7.1-mysqlnd php7.1-xmlrpc php7.1-curl php-redis -y
  sudo apt install php7.1-gd php7.1-imagick php7.1-cli php-pear php7.1-dev php7.1-imap php7.1-mcrypt -y
  # Configure the PHP installation
  ConfigurePHP
}


ConfigurePHP() {
  # Update the PHP owner and group to the newly created system user
  sudo sed -i "s/www-data/$USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
  # Update the server upload size limit of PHP
  sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 64M/g" /etc/php/7.1/fpm/php.ini
  sudo sed -i "s/post_max_size = 8M/post_max_size = 64M/g" /etc/php/7.1/fpm/php.ini
  # Restart the PHP service
  RestartPHPService
}


InstallMySQL() {
  # Check for package updates
  UpdatePackages
  # Configure the MySQL username and password
  echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | sudo debconf-set-selections
  echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | sudo debconf-set-selections
  # Install the MySQL package
  sudo apt install mysql-server -y
  # Configure the MySQL installation
  ConfigureMySQL
}


ConfigureMySQL() {
  # Update temp variables in the installer MySQL file
  sudo sed -i "s/%DATABASE%/$DATABASE/g" $SCRIPT_FOLDER/databases/installer.sql
  sudo sed -i "s/%USERNAME%/$USERNAME/g" $SCRIPT_FOLDER/databases/installer.sql
  sudo sed -i "s/%MYSQL_PASSWORD%/$MYSQL_PASSWORD/g" $SCRIPT_FOLDER/databases/installer.sql
  # Run the installer MySQL query
  mysql --verbose -u root -p$MYSQL_PASSWORD < $SCRIPT_FOLDER/databases/installer.sql
}


RestartPHPService() {
  # Restarting the PHP service
  sudo service php7.1-fpm restart
}


InstallNginx() {
  # Download the most recent Nginx repository
  sudo add-apt-repository ppa:nginx/development -y
  # Check for package updates
  UpdatePackages
  # Install the Nginx package
  sudo apt install nginx -y
  # Configure the Nginx installation
  ConfigureNginx
}


ConfigureNginx() {
  # Enable the PHP script module in Nginx
  sudo echo 'fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> /etc/nginx/fastcgi_params
  # Backup the original Nginx config file
  sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.bkp
  # Update temp variables in new Nginx config file
  sudo sed -i "s/%USERNAME%/$USERNAME/g" $SCRIPT_FOLDER/nginx/nginx.conf
  # Move the configured Nginx config file
  sudo mv -v $SCRIPT_FOLDER/nginx/nginx.conf /etc/nginx/nginx.conf
  # Configure the server block
  ConfigureServerBlock
  # Restart the Nginx web server
  RestartNginxService
}


RestartNginxService() {
  # Restart the Nginx web server
  sudo service nginx restart
}


ConfigureWebServer() {
  # Create web server directories
  sudo mkdir -p /home/$USERNAME/$SITE_DOMAIN/backups
  sudo mkdir -p /home/$USERNAME/$SITE_DOMAIN/public
  sudo mkdir -p /home/$USERNAME/$SITE_DOMAIN/cache
  sudo mkdir -p /home/$USERNAME/$SITE_DOMAIN/logs
  # Create temporary empty log files
  sudo touch /home/$USERNAME/$SITE_DOMAIN/logs/access.log
  sudo touch /home/$USERNAME/$SITE_DOMAIN/logs/errors.log
  # Move favicon and robots file into public directory
  sudo mv -v $SCRIPT_FOLDER/assets/robots.txt /home/$USERNAME/$SITE_DOMAIN/public/robots.txt
  sudo mv -v $SCRIPT_FOLDER/assets/favicon.ico /home/$USERNAME/$SITE_DOMAIN/public/favicon.ico
  # Update permissions of the web directory
  sudo chmod -R 755 /home/$USERNAME/$SITE_DOMAIN
  sudo chown -R $USERNAME:$USERNAME /run/php
  sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/$SITE_DOMAIN
  # Install WordPress into the public web directory
  InstallWordPress
}


ConfigureServerBlock() {
  # Remove the default Nginx server blocks
  sudo rm /etc/nginx/sites-available/default
  sudo rm /etc/nginx/sites-enabled/default
  # Update temp variables in the server-block conf files
  sudo sed -i "s/%SERVER_NAMES%/$SERVER_NAMES/g" $SCRIPT_FOLDER/nginx/server-block.conf
  sudo sed -i "s/%SITE_DOMAIN%/$SITE_DOMAIN/g" $SCRIPT_FOLDER/nginx/server-block.conf
  sudo sed -i "s/%USERNAME%/$USERNAME/g" $SCRIPT_FOLDER/nginx/server-block.conf
  # Move the server-block conf file into the Nginx directory
  sudo mv -v $SCRIPT_FOLDER/nginx/server-block.conf /etc/nginx/sites-available/$SITE_DOMAIN
  # Create a symlink to the server-block conf file
  sudo ln -s /etc/nginx/sites-available/$SITE_DOMAIN /etc/nginx/sites-enabled/$SITE_DOMAIN
  # Install a self-signed SSL certificate (if domain is set)
  if [[ $ISSET_DOMAIN = "true" ]]; then InstallSSLCertificate; fi
  # Restart the Nginx web server
  RestartNginxService
}


InstallSSLCertificate() {
  # Generate a self-signed SSL certificate
  echo "$USER_EMAIL" | sudo letsencrypt certonly --webroot -w /home/$USERNAME/$SITE_DOMAIN/public -d $SITE_DOMAIN
  # Replace the default port 80 with port 443
  sudo sed -i "s/80; /443 ssl http2;/g" /etc/nginx/sites-available/$SITE_DOMAIN
  # Uncomment the SSL certificate paths from the server block
  sudo sed -i "s/# config //g" /etc/nginx/sites-available/$SITE_DOMAIN
  # Uncomment the SSL certificate parameters from the Nginx config
  sudo sed -i "s/# config //g" /etc/nginx/nginx.conf
}


InstallWordPress() {
  # Download the latest version of WordPress
  curl -o /home/$USERNAME/wordpress.zip https://wordpress.org/latest.zip
  # Unzip the WordPress download
  unzip /home/$USERNAME/wordpress.zip -d /home/$USERNAME
  # Delete the WordPress zip file
  sudo rm /home/$USERNAME/wordpress.zip
  # Install the WordPress download
  sudo mv -v /home/$USERNAME/wordpress/* /home/$USERNAME/$SITE_DOMAIN/public
  # Delete the WordPress download directory
  sudo rm -rf /home/$USERNAME/wordpress
  # Configure the WordPress installation
  ConfigureWordPress
}


ConfigureWordPress() {
  # Update temp variables in the wp-config file
  sudo sed -i "s/%DATABASE%/$DATABASE/g" $SCRIPT_FOLDER/wordpress/wp-config.php
  sudo sed -i "s/%USERNAME%/$USERNAME/g" $SCRIPT_FOLDER/wordpress/wp-config.php
  sudo sed -i "s/%MYSQL_PASSWORD%/$MYSQL_PASSWORD/g" $SCRIPT_FOLDER/wordpress/wp-config.php
  # Move the configured wp-config file
  sudo mv -v $SCRIPT_FOLDER/wordpress/wp-config.php /home/$USERNAME/$SITE_DOMAIN/public/wp-config.php
  # Install default WordPress plugins
  InsallWordPressPlugins
}


InsallWordPressPlugins() {
  # Delete any existing WordPress plugins
  sudo rm -r /home/$USERNAME/$SITE_DOMAIN/public/wp-content/plugins/*
  # Install default WordPress plugins
  for plugin in $SCRIPT_FOLDER/wordpress/wp-plugins/*.zip; do
    unzip "$plugin" -d /home/$USERNAME/$SITE_DOMAIN/public/wp-content/plugins/
  done
}


ConfigureCache() {
  # Enable the maxmemory parameter
  sudo sed -i "s/# maxmemory/maxmemory/g" /etc/redis/redis.conf
  # Restart the Redis cache service
  sudo service redis-server restart
  # Restart the PHP service
  RestartPHPService
  # Restart the Nginx web server
  RestartNginxService
}


StartInstaller() {
  PromptSettings
  ConfigureSystem
  ConfigureWebServer
  ConfigureCache

  echo "Installation complete!"
  echo "Your server password is: $USER_PASSWORD"
  echo "Your MySQL password is: $MYSQL_PASSWORD"

}

StartInstaller
