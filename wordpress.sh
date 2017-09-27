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

# 1. UPDATE server hostname
echo $SITEURL > /etc/hostname


# 2. CONFIGURE timezone
dpkg-reconfigure tzdata


# 3. UPDATE packages
sudo apt update


# 4. UPGRADE packages
sudo apt upgrade -y


# 5. REMOVE old packages
sudo apt autoremove -y


# 6. INSTALL common packages
sudo apt install software-properties-common


# 7. CREATE new server user
sudo adduser $USERNAME --disabled-password
echo "$USERNAME:$PASSWORD" | sudo chpasswd


# 8. add user to sudo group
sudo usermod -aG sudo $USERNAME


# 9. DISABLE root login via SSH
sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config


# 10. RESTART the SSH server
sudo service ssh restart


# 11. INSTALL UFW firewall
sudo apt install ufw -y


# 12. UPDATE firewalls
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https


# 13. ENABLE the UFW firewall
sudo ufw enable


# 14. INSTALL Fail2Ban
sudo apt install fail2ban -y


# 15. START Fail2Ban
sudo service fail2ban start


# 16. INSTALL Nginx
sudo add-apt-repository ppa:nginx/development -y
sudo apt update
sudo apt install nginx -y


# 18. ENABLE PHP to load in Nginx
sudo echo "fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;" >> /etc/nginx/fastcgi_params


# 19. RESTART the Nginx web server
sudo service nginx restart


# 20. INSTALL latest version of PHP and modules
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install php7.1-fpm php7.1-common php7.1-mysqlnd php7.1-xmlrpc php7.1-curl php7.1-gd php7.1-imagick php7.1-cli php-pear php7.1-dev php7.1-imap php7.1-mcrypt -y


# 21. CONFIGURE PHP owners and groups
sudo sed -i "s/user = www-data/user = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
sudo sed -i "s/group = www-data/group = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
sudo sed -i "s/listen.owner = www-data/listen.owner = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf
sudo sed -i "s/listen.group = www-data/listen.group = $USERNAME/g" /etc/php/7.1/fpm/pool.d/www.conf


# 22. CONFIGURE PHP upload sizes
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 64M/g" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 64M/g" /etc/php/7.1/fpm/php.ini


# 23. RESTART PHP service
sudo service php7.1-fpm restart


# 24. INSTALL MariaDB
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository "deb [arch=amd64,i386,ppc64el] http://mirror.nodesdirect.com/mariadb/repo/10.1/ubuntu xenial main" -y
sudo apt update
sudo apt install mariadb-server -y


# 25. CONFIGURE default system database tables
sudo mysql_install_db
sudo mysql_secure_installation


# 26. CONFIGURE a "catch-all" server block
#  A. REMOVE default Nginx server blocks
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default
#  B. RENAME the old Nginx config as backup
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.bkp
#  C. REPLACE old Nginx config with new one
sudo mv nginx.conf /etc/nginx/nginx.conf
#  D. REPLACE temp_user with current user
sudo sed -i "s/temp_username/$USERNAME/g" /etc/nginx/nginx.conf


# 27. RESTART the Nginx web server
sudo service nginx restart


# 28. CREATE public directories for website
sudo mkdir -p ~/$SITEURL/public
sudo mkdir -p ~/$SITEURL/logs
sudo chmod -R 755 ~/$SITEURL


# 29. CREATE new Nginx block config file
sudo mv server-block.conf /etc/nginx/sites-available/$SITEURL
sudo sed -i "s/temp_siteurl/$SITEURL/g" /etc/nginx/sites-available/$SITEURL


# 30. CREATE a symlink to the new config file
sudo ln -s /etc/nginx/sites-available/$SITEURL /etc/nginx/sites-enabled/$SITEURL


# 31. RERSTART the Nginx web server
sudo service nginx restart


# 32. CREATE and CONFIGURE the new database
mysql -u $DBUSERNAME -p$DBPASSWORD -Bse "CREATE DATABASE $DBNAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;"
mysql -u $DBUSERNAME -p$DBPASSWORD -Bse "CREATE USER '$DBUSERNAME'@'localhost' IDENTIFIED BY '$DBPASSWORD';"
mysql -u $DBUSERNAME -p$DBPASSWORD -Bse "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSERNAME'@'localhost';"
mysql -u $DBUSERNAME -p$DBPASSWORD -Bse "GRANT SELECT, INSERT, UPDATE, DELETE ON $DBNAME.* TO '$DBUSERNAME'@'localhost';"
mysql -u $DBUSERNAME -p$DBPASSWORD -Bse "FLUSH PRIVILEGES;"


# 32. DOWNLOAD the wp-cli package
cd ~/
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
php wp-cli.phar --info
sudo chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp


# 33. DOWNLOAD WordPress into the domain directory
cd ~/$SITEURL/public
wp core download


# 34. CONFIGURE the new WordPress installation
wp core config --dbname=$DBNAME --dbuser=$DBUSERNAME --dbpass=$DBPASSWORD


# 35. INSTALL WordPress
wp core install --url=$SITEURL --title=$SITETITLE --admin_user=$WPUSERNAME --admin_email=$WPEMAIL --admin_password=$WPPASSWORD
