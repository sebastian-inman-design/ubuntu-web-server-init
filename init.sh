#!/bin/sh

echo "==================================================="
echo "Ubuntu 16.04 Web Server Configuration Shell Scripts"
echo "Created by Sebastian Inman <sebastian@inman.design>"
echo "==================================================="
echo "                                                   "
echo "                                                   "

PS3='Please select which web server you would like to configure:'
options=("apache" "nginx")
select opt in "${options[@]}"; do
  case $opt in
    "apache")
      echo "installing apache..."
      break ;;
    "nginx")
      echo "installing nginx..."
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
