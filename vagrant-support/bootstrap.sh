#!/usr/bin/env bash

PROJECT_ROOT_DIR=/vagrant
BOOTSTRAP_DIR=/vagrant/vagrant-bootstrap

# setup packages

cd /etc/apt/
cp sources.list sources.list.origin
cat sources.list.origin | sed s/archive.ubuntu.com/mirrors.163.com/ > sources.list

debconf-set-selections <<< 'mysql-server mysql-server/root_password password gamebox'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password gamebox'

apt-get update -y
apt-get upgrade -y
apt-get install -y mysql-server mysql-client

cd /vagrant/
sudo ./install.sh

# done
echo ALL DONE. please use browser open http://localhost:18088/

