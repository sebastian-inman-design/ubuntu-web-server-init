#!/bin/sh

echo "Installing MySQL"
sudo apt install mysql-server -y
sudo mysql_secure_installation
