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
IP_ADDRESS=$(curl -s http://icanhazip.com)
CURRENT_DATE=`date '+%Y-%m-%d %H:%M:%S'`


Welcome() {

  eclipse > $SCRIPT_FOLDER/installer.log 2>&1

  clear
  echo ""
  echo -e "${CLR_RESET}"
  echo -e "${CLR_YELLOW}EEEEEEEEEEEEEEEEEE EEEEEEEEEEEEEEEEEEE"
  echo -e "${CLR_YELLOW}EEEEEEEEEEEEEEEEE   EEEEEEEEEEEEEEEEEE"
  echo -e "${CLR_YELLOW}EEEE                              EEEE    ${CLR_RESET}Seeds Creative Services WordPress Installer"
  echo -e "${CLR_YELLOW}EEEE                              EEEE    ${CLR_RESET}Made by Sebastian Inman ${CLR_CYAN}sebastian@seedscs.com"
  echo -e "${CLR_YELLOW}EEEEEEEEEEEE              EEEEEEEEEEEE"
  echo -e "${CLR_YELLOW}EEEEEEEEEEEE              EEEEEEEEEEEE    ${CLR_RESET}This script automatically installs and configures"
  echo -e "${CLR_YELLOW}EEEE                              EEEE    ${CLR_RESET}a fast and secure Nginx web server with the latest"
  echo -e "${CLR_YELLOW}EEEE                              EEEE    ${CLR_RESET}build of WordPress."
  echo -e "${CLR_YELLOW}EEEEEEEEEEEEEEEEE   EEEEEEEEEEEEEEEEEE"
  echo -e "${CLR_YELLOW}EEEEEEEEEEEEEEEEEE EEEEEEEEEEEEEEEEEEE"
  echo -e "${CLR_RESET}"
  echo ""
  echo ""

  read -n 1 -s -r -p "Press any key to begin the installation process..."
  echo ""
  StartInstaller

}


PromptSettings() {
  # Prompt user for their full name
  echo ""
  read -p "Enter your full name: " PROMPT_REAL_NAME
  REAL_NAME=$PROMPT_REAL_NAME
  # Prompt user for their system username
  read -p "Enter your username: " PROMPT_USERNAME
  USERNAME=$PROMPT_USERNAME
  # Prompt user for their email address
  read -p "Enter your email address: " PROMPT_EMAIL
  USER_EMAIL=$PROMPT_EMAIL
  # Prompt user for their password
  if [[ SECURE_INSTALL = "false" ]]; then
    read -p "Enter your password: " PROMPT_PASSWORD
    USER_PASSWORD=$PROMPT_PASSWORD
    MYSQL_PASSWORD=$USER_PASSWORD
  fi
  # Prompt user for the servers domain name
  read -p "Enter the domain for this server: " PROMPT_DOMAIN
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
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Creating new user '$USERNAME'..."
  sudo adduser $USERNAME --gecos "$REAL_NAME,,," --disabled-password > $SCRIPT_FOLDER/installer.log 2>&1
  echo "$USERNAME:$USER_PASSWORD" | sudo chpasswd > $SCRIPT_FOLDER/installer.log 2>&1
  sudo usermod -aG sudo $USERNAME > $SCRIPT_FOLDER/installer.log 2>&1
  sudo mkdir -p /home/$USERNAME
  sudo chown -R $USERNAME:$USERNAME /home/$USERNAME
}


UpdatePackages() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Checking for package updates..."
  sudo apt-get update > $SCRIPT_FOLDER/installer.log 2>&1
}


InstallUpdates() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Installing package updates..."
  sudo apt-get -y upgrade > $SCRIPT_FOLDER/installer.log 2>&1
}


ConfigureSystem() {
  # Update the servers hostname to match the domain
  echo $SITE_DOMAIN > /etc/hostname
  hostname -F /etc/hostname
  # Set the servers local timezone to PST
  echo "America/Los_Angeles" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata > $SCRIPT_FOLDER/installer.log 2>&1
  # Update the current time variable
  CURRENT_DATE=`date '+%Y-%m-%d %H:%M:%S'`
  # Check for package updates
  UpdatePackages
  # Install package updates
  InstallUpdates
  # Remove old packages
  # TODO sudo apt-get -y autoremove > $SCRIPT_FOLDER/installer.log 2>&1
  # Install system dependencies
  InstallDependencies
  # Configure the firewall
  ConfigureFirewall
  # Start the Fail2Ban service
  sudo service fail2ban start > $SCRIPT_FOLDER/installer.log 2>&1
  # Install and configure PHP
  InstallPHP
  # Install and configure Nginx
  InstallNginx
  # Install and configure MySQL
  InstallMySQL
}


InstallDependencies() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Installing package dependencies..."
  # Install the UFW package
  sudo apt-get install -y ufw > $SCRIPT_FOLDER/installer.log 2>&1
  # Install the unzip package
  sudo apt-get install -y unzip > $SCRIPT_FOLDER/installer.log 2>&1
  # Install the Fail2Ban package
  sudo apt-get install -y fail2ban > $SCRIPT_FOLDER/installer.log 2>&1
  # Install the libpcre3 package
  sudo apt-get install -y libpcre3 > $SCRIPT_FOLDER/installer.log 2>&1
  # Install the LetsEncrypt package
  sudo apt-get install -y letsencrypt > $SCRIPT_FOLDER/installer.log 2>&1
  # Install Redis cache packages
  sudo apt-get install -y redis-server > $SCRIPT_FOLDER/installer.log 2>&1
}


ConfigureFirewall() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Configuring firewall..."
  # Allow SSH through firewall
  sudo ufw allow ssh > $SCRIPT_FOLDER/installer.log 2>&1
  # Allow HTTP through firewall
  sudo ufw allow http > $SCRIPT_FOLDER/installer.log 2>&1
  # Allow HTTPS through firewall
  sudo ufw allow https > $SCRIPT_FOLDER/installer.log 2>&1
  # Enable the firewall
  echo "Y" | sudo ufw enable > $SCRIPT_FOLDER/installer.log 2>&1
}


InstallPHP() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Installing PHP with core modules..."
  # Download the most recent PHP repository
  sudo add-apt-repository -y ppa:ondrej/php > $SCRIPT_FOLDER/installer.log 2>&1
  # Check for package updates
  UpdatePackages
  # Install PHP and common modules
  sudo apt-get install -y php7.1-fpm php7.1-common php7.1-mysqlnd php7.1-xmlrpc php7.1-curl php-redis > $SCRIPT_FOLDER/installer.log 2>&1
  sudo apt-get install -y php7.1-gd php7.1-imagick php7.1-cli php-pear php7.1-dev php7.1-imap php7.1-mcrypt > $SCRIPT_FOLDER/installer.log 2>&1
  # Configure the PHP installation
  ConfigurePHP
}


ConfigurePHP() {
  # Update the PHP owner and group to the newly created system user
  sudo sed -i "s/www-data/$USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
  # Update the server upload size limit of PHP
  sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 64M/g" /etc/php/7.1/fpm/php.ini
  sudo sed -i "s/post_max_size = 8M/post_max_size = 64M/g" /etc/php/7.1/fpm/php.ini
}


InstallMySQL() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Installing MySQL..."
  # Check for package updates
  UpdatePackages
  # Configure the MySQL username and password
  echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | sudo debconf-set-selections
  echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | sudo debconf-set-selections
  # Install the MySQL package
  sudo apt-get install -y mysql-server > $SCRIPT_FOLDER/installer.log 2>&1
  # Configure the MySQL installation
  ConfigureMySQL
}


ConfigureMySQL() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Configuring MySQL databases..."
  # Configure the local MySQL configuration
  echo "$MYSQL_PASSWORD" | mysql_config_editor set --login-path=local --host=localhost --user=$USERNAME --password
  # Update temp variables in the installer MySQL file
  sudo sed -i "s/%DATABASE%/$DATABASE/g" $SCRIPT_FOLDER/databases/installer.sql
  sudo sed -i "s/%USERNAME%/$USERNAME/g" $SCRIPT_FOLDER/databases/installer.sql
  sudo sed -i "s/%MYSQL_PASSWORD%/$MYSQL_PASSWORD/g" $SCRIPT_FOLDER/databases/installer.sql
  # Run the installer MySQL query
  mysql --login-path=local -e < $SCRIPT_FOLDER/databases/installer.sql
}


RestartPHPService() {
  # Restarting the PHP service
  sudo service php7.1-fpm restart
}


InstallNginx() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Installing the Nginx server..."
  # Download the most recent Nginx repository
  sudo add-apt-repository -y ppa:nginx/development > $SCRIPT_FOLDER/installer.log 2>&1
  # Check for package updates
  UpdatePackages
  # Install the Nginx package
  sudo apt-get install -y nginx > $SCRIPT_FOLDER/installer.log 2>&1
  # Configure the Nginx installation
  ConfigureNginx
}


ConfigureNginx() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Configuring the Nginx server to host $SITE_DOMAIN..."
  # Enable the PHP script module in Nginx
  sudo echo 'fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> /etc/nginx/fastcgi_params
  # Backup the original Nginx config file
  sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.bkp
  # Update temp variables in new Nginx config file
  sudo sed -i "s/%USERNAME%/$USERNAME/g" $SCRIPT_FOLDER/nginx/nginx.conf
  # Move the configured Nginx config file
  sudo mv $SCRIPT_FOLDER/nginx/nginx.conf /etc/nginx/nginx.conf
  # Configure the server block
  ConfigureServerBlock
}


RestartNginxService() {
  # Restart the Nginx web server
  sudo service nginx restart
}


ConfigureWebServer() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Configuring the $SITE_DOMAIN server block..."
  # Create web server directories
  sudo mkdir -p /home/$USERNAME/$SITE_DOMAIN/backups
  sudo mkdir -p /home/$USERNAME/$SITE_DOMAIN/public
  sudo mkdir -p /home/$USERNAME/$SITE_DOMAIN/cache
  sudo mkdir -p /home/$USERNAME/$SITE_DOMAIN/logs
  # Create temporary empty log files
  sudo touch /home/$USERNAME/$SITE_DOMAIN/logs/access.log
  sudo touch /home/$USERNAME/$SITE_DOMAIN/logs/errors.log
  # Move favicon and robots file into public directory
  sudo mv $SCRIPT_FOLDER/assets/robots.txt /home/$USERNAME/$SITE_DOMAIN/public/robots.txt
  sudo mv $SCRIPT_FOLDER/assets/favicon.ico /home/$USERNAME/$SITE_DOMAIN/public/favicon.ico
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
  sudo mv $SCRIPT_FOLDER/nginx/server-block.conf /etc/nginx/sites-available/$SITE_DOMAIN
  # Create a symlink to the server-block conf file
  sudo ln -s /etc/nginx/sites-available/$SITE_DOMAIN /etc/nginx/sites-enabled/$SITE_DOMAIN
  # Install a self-signed SSL certificate (if domain is set)
  # TODO if [[ $ISSET_DOMAIN = "true" ]]; then InstallSSLCertificate; fi
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
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Downloading and installing the latest WordPress build..."
  # Download the latest version of WordPress
  curl -s -o /home/$USERNAME/wordpress.zip https://wordpress.org/latest.zip
  # Unzip the WordPress download
  unzip -qq /home/$USERNAME/wordpress.zip -d /home/$USERNAME
  # Delete the WordPress zip file
  sudo rm /home/$USERNAME/wordpress.zip
  # Install the WordPress download
  sudo mv /home/$USERNAME/wordpress/* /home/$USERNAME/$SITE_DOMAIN/public
  # Delete the WordPress download directory
  sudo rm -rf /home/$USERNAME/wordpress
  # Configure the WordPress installation
  ConfigureWordPress
}


ConfigureWordPress() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Configuring the WordPress installation..."
  # Update temp variables in the wp-config file
  sudo sed -i "s/%DATABASE%/$DATABASE/g" $SCRIPT_FOLDER/wordpress/wp-config.php
  sudo sed -i "s/%USERNAME%/$USERNAME/g" $SCRIPT_FOLDER/wordpress/wp-config.php
  sudo sed -i "s/%MYSQL_PASSWORD%/$MYSQL_PASSWORD/g" $SCRIPT_FOLDER/wordpress/wp-config.php
  # Move the configured wp-config file
  sudo mv $SCRIPT_FOLDER/wordpress/wp-config.php /home/$USERNAME/$SITE_DOMAIN/public/wp-config.php
  # Install default WordPress plugins
  InsallWordPressPlugins
}


InsallWordPressPlugins() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Installing WordPress plugins..."
  # Delete any existing WordPress plugins
  sudo rm -r /home/$USERNAME/$SITE_DOMAIN/public/wp-content/plugins/*
  # Install default WordPress plugins
  for plugin in $SCRIPT_FOLDER/wordpress/wp-plugins/*.zip; do
    unzip -qq "$plugin" -d /home/$USERNAME/$SITE_DOMAIN/public/wp-content/plugins/
  done
}


ConfigureCache() {
  # Enable the maxmemory parameter
  sudo sed -i "s/# maxmemory/maxmemory/g" /etc/redis/redis.conf
}


RestartServices() {
  echo -e "${CLR_YELLOW}[ * ]${CLR_RESET} Restarting system services..."
  # Restart the Redis cache service
  sudo service redis-server restart
  # Restart the PHP service
  RestartPHPService
  # Restart the Nginx web server
  RestartNginxService
}


StartInstaller() {

  START_TIME="$(date -u +%s)"

  sudo touch $SCRIPT_FOLDER/installer.log
  sudo touch $SCRIPT_FOLDER/credentials.log

  PromptSettings
  ConfigureSystem
  ConfigureWebServer
  ConfigureCache
  InstallUpdates
  RestartServices

  FINISH_TIME="$(date -u +%s)"
  ELAPSED_TIME="$(($FINISH_TIME-$START_TIME))"

  echo -e "${CLR_RESET}"
  echo -e "${CLR_GREEN}Completed installation in $(($ELAPSED_TIME/60)) minutes and $(($ELAPSED_TIME%60)) seconds!"
  echo -e "${CLR_RESET}"
  echo -e "${CLR_RESET}Your server password is: ${CLR_CYAN}$USER_PASSWORD"
  echo -e "${CLR_RESET}Your MySQL password is: ${CLR_CYAN}$MYSQL_PASSWORD"
  echo -e "${CLR_RESET}"

}

Welcome
