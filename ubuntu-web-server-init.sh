#!/bin/sh

serverip=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)

Initialize() {
  echo "Ubuntu 16.04 Web Server Configuration Script"
  echo "Created by Sebastian Inman <sebastian@inman.design>"
  UpgradePackages
  ChooseServer
}

UpdatePackages() {
  echo "Please wait while the package list is updated..."
  sudo apt update
}

UpgradePackages() {
  echo "Please wait while the system packages are upgraded..."
  UpdatePackages
  sudo apt upgrade -y
  sudo apt autoremove -y
}

ChooseServer() {
  PS3="Please select which web server to install: "
  options=("Apache" "Nginx")
  select opt in "${options[@]}" "Quit"; do
    case "$REPLY" in
      1 ) echo "You picked $opt which is option $REPLY";;
      2 ) echo "You picked $opt which is option $REPLY";;
      3 ) echo "You picked $opt which is option $REPLY";;

      $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
      *) echo "Invalid option. Try another one."; continue;;

    esac
  done
}

InstallApache() {
  echo "Installing Apache"
  sudo apt install apache2 -y
  echo "ServerName $ipaddress" >> /etc/apache2/apache2.conf
  sudo ufw allow in "Apache Full"
  sudo ufw enable
  echo "Restarting the web server"
  sudo systemctl restart apache2
}

InstallMySQL() {
  echo "Installing MySQL"
  sudo apt update
  sudo apt install mysql-server -y
  sudo mysql_secure_installation
}

InstallPHP() {
  echo "Installing PHP 7"
  sudo apt install php7.0 libapache2-mod-php7.0 -y
}

Initialize
