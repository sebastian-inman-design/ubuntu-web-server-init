#!/bin/bash


REALNAME=""
USERNAME=""
USERMAIL=""
USERPASS=""
USERPASSMD5=""
SITEDOMAIN=""

IPADDRESS=$(curl http://icanhazip.com)
CURRENTDATE=`date '+%Y-%m-%d %H:%M:%S'`
SCRIPTFILE=$(readlink -f "$0")
SCRIPTFOLDER=$(dirname "$SCRIPTFILE")


PromptSettings() {
  # Prompt user for their full name
  read -p "Enter your full name: " PROMPTREALNAME
  REALNAME=$PROMPTREALNAME
  # Prompt user for their system username
  read -p "Enter your username: " PROMPTUSERNAME
  USERNAME=$PROMPTUSERNAME
  # Prompt user for their email address
  read -p "Enter your email address: " PROMPTEMAIL
  USEREMAIL=$PROMPTEMAIL
  # Prompt user for their password
  read -sp "Enter your password: " PROMPTPASSWORD
  USERPASS=$PROMPTPASSWORD
  USERPASSMD5=$(openssl passwd -1 "$USERPASS")
  # Prompt user for the servers domain name
  read -p "Enter the domain for this server: " PROMPTDOMAIN
  SITEDOMAIN=$PROMPTDOMAIN
  # Add the new user to the system
  AddSystemUser
}


AddSystemUser() {
  echo "Adding new system user..."
  sudo adduser $USERNAME --gecos "$REALNAME,,," --disabled-password
  echo "$USERNAME:$PASSWORD" | sudo chpasswd
  usermod -aG sudo $USERNAME
  sudo mkdir -p /home/$USERNAME
  sudo chown -R $USERNAME:$USERNAME /home/$USERNAME
}


UpdatePackages() {
  echo "Checking system for package updates..."
  sudo apt update
}


InstallUpdates() {
  echo "Installing system package updates..."
  sudo apt upgrade -y
}


ConfigureSystem() {
  # Update the servers hostname to match the domain
  echo $SITEDOMAIN > /etc/hostname
  hostname -F /etc/hostname
  # Set the servers local timezone to PST
  echo "America/Los_Angeles" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
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
  # Install the unzip package
  sudo apt install unzip -y
  # Install the expect package
  sudo apt install expect -y
  # Install the UFW package
  sudo apt install ufw -y
  # Install the Fail2Ban package
  sudo apt install fail2ban -y
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
  sudo sed -i "s/listen.owner = www-data/user = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
  sudo sed -i "s/listen.group = www-data/user = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
  sudo sed -i "s/group = www-data/user = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
  sudo sed -i "s/user = www-data/user = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
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
  echo "mysql-server mysql-server/root_password password $PASSWORD" | sudo debconf-set-selections
  echo "mysql-server mysql-server/root_password_again password $PASSWORD" | sudo debconf-set-selections
  # Install the MySQL package
  sudo apt install mysql-server -y
  # Configure the MySQL installation
  ConfigureMySQL
}


ConfigureMySQL() {
  # Update temp variables in the installer MySQL file
  sudo sed -i "s/temp_database/$DATABASE/g" $SCRIPTFOLDER/database/installer.sql
  sudo sed -i "s/temp_username/$USERNAME/g" $SCRIPTFOLDER/database/installer.sql
  sudo sed -i "s/temp_password/$PASSWORD/g" $SCRIPTFOLDER/database/installer.sql
  # Run the installer MySQL query
  mysql --verbose -u root -p$PASSWORD < $SCRIPTFOLDER/database/installer.sql
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
  # Remove the default Nginx server blocks
  sudo rm /etc/nginx/sites-available/default
  sudo rm /etc/nginx/sites-enabled/default
  # Backup the original Nginx config file
  sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.bkp
  # Update temp variables in new Nginx config file
  sudo sed -i "s/temp_username/$USERNAME/g" $SCRIPTFOLDER/nginx.conf
  # Move the configured Nginx config file
  sudo mv -v $SCRIPTFOLDER/nginx.conf /etc/nginx/nginx.conf
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
  sudo mkdir -p /home/$USERNAME/$SITEDOMAIN/backups
  sudo mkdir -p /home/$USERNAME/$SITEDOMAIN/public
  sudo mkdir -p /home/$USERNAME/$SITEDOMAIN/cache
  sudo mkdir -p /home/$USERNAME/$SITEDOMAIN/logs
  # Create temporary empty log files
  sudo touch /home/$USERNAME/$SITEDOMAIN/logs/access.log
  sudo touch /home/$USERNAME/$SITEDOMAIN/logs/errors.log
  # Move favicon and robots file into public directory
  sudo mv -v $SCRIPTFOLDER/robots.txt /home/$USERNAME/$SITEDOMAIN/public/robots.txt
  sudo mv -v $SCRIPTFOLDER/favicon.ico /home/$USERNAME/$SITEDOMAIN/public/favicon.ico
  # Update permissions of the web directory
  sudo chmod -R 755 /home/$USERNAME/$SITEDOMAIN
  # Install WordPress into the public web directory
  InstallWordPress
}


ConfigureServerBlock() {
  # Update temp variables in the server-block conf files
  sudo sed -i "s/temp_ipaddress/$IPADDRESS/g" $SCRIPTFOLDER/server-block.conf
  sudo sed -i "s/temp_sitedomain/$SITEDOMAIN/g" $SCRIPTFOLDER/server-block.conf
  sudo sed -i "s/temp_username/$USERNAME/g" $SCRIPTFOLDER/server-block.conf
  # Move the server-block conf file into the Nginx directory
  sudo mv -v $SCRIPTFOLDER/server-block.conf /etc/nginx/sites-available/$SITEDOMAIN
  # Create a symlink to the server-block conf file
  sudo ln -s /etc/nginx/sites-available/$SITEDOMAIN /etc/nginx/sites-enabled/$SITEDOMAIN
}


InstallWordPress() {
  # Download the latest version of WordPress
  curl -o /home/$USERNAME/wordpress.zip https://wordpress.org/latest.zip
  # Unzip the WordPress download
  unzip /home/$USERNAME/wordpress.zip -d /home/$USERNAME
  # Delete the WordPress zip file
  sudo rm /home/$USERNAME/wordpress.zip
  # Install the WordPress download
  sudo mv -v /home/$USERNAME/wordpress/* /home/$USERNAME/$SITEDOMAIN/public
  # Delete the WordPress download directory
  sudo rm -rf /home/$USERNAME/wordpress
  # Configure the WordPress installation
  ConfigureWordPress
}


ConfigureWordPress() {
  # Update temp variables in the wp-config file
  sudo sed -i "s/temp_database/$DATABASE/g" $SCRIPTFOLDER/wp-config.php
  sudo sed -i "s/temp_username/$USERNAME/g" $SCRIPTFOLDER/wp-config.php
  sudo sed -i "s/temp_password/$PASSWORD/g" $SCRIPTFOLDER/wp-config.php
  # Move the configured wp-config file
  sudo mv -v $SCRIPTFOLDER/wp-config.php /home/$USERNAME/$SITEDOMAIN/public/wp-config.php
  # Install default WordPress plugins
  InsallWordPressPlugins
}


InsallWordPressPlugins() {
  # Delete any existing WordPress plugins
  sudo rm -r /home/$USERNAME/$SITEDOMAIN/public/wp-content/plugins/*
  # Install default WordPress plugins
  for plugin in $SCRIPTFOLDER/wp-plugins/*.zip; do
    unzip "$plugin" -d /home/$USERNAME/$SITEDOMAIN/public/wp-content/plugins/
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
}

StartInstaller
