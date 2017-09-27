#!/bin/bash

SEED_NAME="Seeds Creative Services"
SEED_TITLE="$SEED_NAME - WordPress Installation"

DEFAULT_URL="website.com"
DEFAULT_EMAIL="sebastian@seedscs.com"
DEFAULT_USERNAME="sebastian"
DEFAULT_PASSWORD="7jfH80!?xxX"

USERNAME=$DEFAULT_USERNAME
PASSWORD=$DEFAULT_PASSWORD

SITEURL=$DEFAULT_URL
SITETITLE=$SEED_TITLE
SITEADMIN=$DEFAULT_EMAIL

DBNAME="website"
DBUSERNAME=$DEFAULT_USERNAME
DBPASSWORD=$DEFAULT_PASSWORD

WPEMAIL=$DEFAULT_EMAIL
WPUSERNAME=$DEFAULT_USERNAME
WPPASSWORD=$DEFAULT_PASSWORD

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")


# 1. UPDATE server hostname
echo "Updating the server hostname: $SITEURL"
echo $SITEURL > /etc/hostname


# 2. CONFIGURE timezone
echo "Configuring the server timezone..."
echo "America/Los_Angeles" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata


# 3. UPDATE packages
echo "Updating server packages..."
sudo apt update


# 4. UPGRADE packages
echo "Installing package updates..."
sudo apt upgrade -y


# 5. REMOVE old packages
echo "Removing out of date packages..."
sudo apt autoremove -y


# 6. INSTALL common packages
echo "Installing common server packages..."
sudo apt install software-properties-common -y


# 7. INSTALL Expect package
echo "Installing the Expect package..."
sudo apt update
sudo apt install expect -y


# 7. CREATE new server user
echo "Creating new system user: $USERNAME..."
sudo adduser --disabled-password --gecos "" $USERNAME
echo "$USERNAME:$PASSWORD" | sudo chpasswd


# 8. add user to sudo group
echo "Adding $USERNAME to sudo group..."
sudo usermod -aG sudo $USERNAME


# 9. switch to the new user
echo su $USERNAME
echo "$PASSWORD" | sudo ls


# 9. DISABLE root login via SSH
echo "Disabling root login to server..."
sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config


# 10. RESTART the SSH server
echo "Restarting the SSH server..."
sudo service ssh restart


# 11. INSTALL UFW firewall
echo "Installing the UFW firewall package..."
sudo apt update
sudo apt install ufw -y


# 12. UPDATE firewalls
echo "Updating allowed UFW ports..."
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https


# 13. ENABLE the UFW firewall
echo "Starting the UFW firewall service..."
echo "y" | sudo ufw enable


# 14. INSTALL Fail2Ban
echo "Installing the Fail2Ban package..."
sudo apt update
sudo apt install fail2ban -y


# 15. START Fail2Ban
echo "Starting the Fail2Ban service..."
sudo service fail2ban start


# 16. INSTALL Nginx
echo "Installing current Nginx package..."
sudo add-apt-repository ppa:nginx/development -y
sudo apt update
sudo apt install nginx -y


# 18. ENABLE PHP to load in Nginx
echo "Setting up Nginx PHP params..."
sudo echo 'fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> /etc/nginx/fastcgi_params


# 19. RESTART the Nginx web server
echo "Restarting Nginx web server..."
sudo service nginx restart


# 20. INSTALL latest version of PHP and modules
echo "Installing current PHP package and PHP modules..."
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install php7.1-fpm php7.1-common php7.1-mysqlnd php7.1-xmlrpc php7.1-curl php7.1-gd php7.1-imagick php7.1-cli php-pear php7.1-dev php7.1-imap php7.1-mcrypt -y


# 21. CONFIGURE PHP owners and groups
echo "Configuring PHP owners and groups..."
sudo sed -i "s/user = www-data/user = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
sudo sed -i "s/group = www-data/group = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
sudo sed -i "s/listen.owner = www-data/listen.owner = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
sudo sed -i "s/listen.group = www-data/listen.group = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf


# 22. CONFIGURE PHP upload sizes
echo "Configuring PHP upload sizes..."
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 64M/g" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 64M/g" /etc/php/7.1/fpm/php.ini


# 23. RESTART PHP service
echo "Restarting the PHP service..."
sudo service php7.1-fpm restart


# 26. CONFIGURE a "catch-all" server block
#  A. REMOVE default Nginx server blocks
echo "Removing default Nginx server blocks..."
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default
#  B. RENAME the old Nginx config as backup
echo "Backing up original Nginx config file..."
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.bkp
#  C. REPLACE old Nginx config with new one
echo "Creating new Nginx config file..."
sudo mv $SCRIPTPATH/nginx.conf /etc/nginx/nginx.conf
#  D. REPLACE temp_user with current user
echo "Updating the new Nginx config file..."
sudo sed -i "s/temp_username/$USERNAME/g" /etc/nginx/nginx.conf


# 27. RESTART the Nginx web server
echo "Restarting the Nginx web server..."
sudo service nginx restart


# 28. CREATE public directories for website
echo "Creating domain web directories..."
sudo mkdir -p ~/$SITEURL/public
sudo mkdir -p ~/$SITEURL/logs
sudo chmod -R 755 ~/$SITEURL


# 29. CREATE new Nginx block config file
echo "Creating new Nginx server block config file..."
sudo mv $SCRIPTPATH/server-block.conf /etc/nginx/sites-available/$SITEURL
sudo sed -i "s/temp_siteurl/$SITEURL/g" /etc/nginx/sites-available/$SITEURL
sudo sed -i "s/temp_username/$USERNAME/g" /etc/nginx/sites-available/$SITEURL


# 30. CREATE a symlink to the new config file
sudo ln -s /etc/nginx/sites-available/$SITEURL /etc/nginx/sites-enabled/$SITEURL


# 31. RERSTART the Nginx web server
sudo service nginx restart


# 24. INSTALL MySQL
# echo "Installing the MySQL package..."
# echo "mysql-server mysql-server/root_password password $DBPASSWORD" | sudo debconf-set-selections
# echo "mysql-server mysql-server/root_password_again password $DBPASSWORD" | sudo debconf-set-selections
# sudo apt update
# sudo apt install mysql-server -y


# 25. CONFIGURE MySQL with mysql_secure_installation
# SECURE_MYSQL=$(expect -c "
# set timeout 10
# spawn mysql_secure_installation
# expect \"Enter current password for root (enter for none):\"
# send \"$DBPASSWORD\r\"
# expect \"Change the root password?\"
# send \"n\r\"
# expect \"Remove anonymous users?\"
# send \"y\r\"
# expect \"Disallow root login remotely?\"
# send \"y\r\"
# expect \"Remove test database and access to it?\"
# send \"y\r\"
# expect \"Reload privilege tables now?\"
# send \"y\r\"
# expect eof
# ")

# echo "$SECURE_MYSQL"
# sudo purge expect -y


# 32. CREATE and CONFIGURE the new database
# mysql -u $DBUSERNAME -p$DBPASSWORD -Bse "CREATE DATABASE $DBNAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;"
# mysql -u $DBUSERNAME -p$DBPASSWORD -Bse "CREATE USER '$DBUSERNAME'@'localhost' IDENTIFIED BY '$DBPASSWORD';"
# mysql -u $DBUSERNAME -p$DBPASSWORD -Bse "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSERNAME'@'localhost';"
# mysql -u $DBUSERNAME -p$DBPASSWORD -Bse "GRANT SELECT, INSERT, UPDATE, DELETE ON $DBNAME.* TO '$DBUSERNAME'@'localhost';"
# mysql -u $DBUSERNAME -p$DBPASSWORD -Bse "FLUSH PRIVILEGES;"


# 32. DOWNLOAD the wp-cli package
cd ~/
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
php ~/wp-cli.phar --info
sudo chmod +x ~/wp-cli.phar
sudo mv ~/wp-cli.phar /usr/local/bin/wp


# 33. DOWNLOAD WordPress into the domain directory
cd ~/$SITEURL/public
sudo -u $USERNAME -i -- wp core download


# 34. CONFIGURE the new WordPress installation
sudo -u $USERNAME -i -- wp core config --dbname=$DBNAME --dbuser=$DBUSERNAME --dbpass=$DBPASSWORD


# 35. INSTALL WordPress
sudo -u $USERNAME -i -- wp core install --url=$SITEURL --title=$SITETITLE --admin_user=$WPUSERNAME --admin_email=$WPEMAIL --admin_password=$WPPASSWORD


# 36. SELF DESTRUCT
sudo rm -rf $SCRIPTPATH
