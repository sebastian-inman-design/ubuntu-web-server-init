#!/bin/bash

serverip=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)

echo "Installing Apache"
sudo apt install apache2 -y
echo "ServerName $ipaddress" >> /etc/apache2/apache2.conf
sudo ufw allow in "Apache Full"
sudo ufw enable
echo "Restarting the web server"
sudo systemctl restart apache2
