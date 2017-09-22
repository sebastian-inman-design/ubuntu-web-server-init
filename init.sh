#!/bin/sh

echo "                                                   "
echo "==================================================="
echo "Ubuntu 16.04 Web Server Configuration Shell Scripts"
echo "Created by Sebastian Inman <sebastian@inman.design>"
echo "==================================================="
echo "                                                   "
echo "                                                   "


PS3='Please select which web server you would like to configure:'
select SERVER in apache nginx cancel; do
  case "$SERVER" in
    "apache")
      echo "install apache..." ;;
    "nginx")
      echo "install nginx..." ;;
    "cancel")
      break ;;
  esac
done


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
