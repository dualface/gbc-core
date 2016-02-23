#!/usr/bin/env bash

PROJECT_ROOT_DIR=/vagrant
BOOTSTRAP_DIR=/vagrant/vagrant-bootstrap

function setup()
{
    # setup packages
    cd /etc/apt/
    cp sources.list sources.list.origin
    cat sources.list.origin | sed s/archive.ubuntu.com/mirrors.aliyun.com/ > sources.list

    debconf-set-selections <<< 'mysql-server mysql-server/root_password password gamebox'
    debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password gamebox'

    apt-get update -y
    apt-get upgrade -y
    apt-get install -y mysql-server mysql-client

    cd /vagrant/
    sudo ./install.sh

    echo "INSTALL COMPLETED."
    echo ""
    echo ""
}

if [ ! -f /opt/gbc-core/start_server ]; then
    setup
fi

# done
/opt/gbc-core/start_server --debug
echo ""
echo "waiting 5 seconds..."
sleep 5
echo ""
echo ""
/opt/gbc-core/check_server

echo ""
echo ""
echo ALL DONE. please use browser open http://localhost:8088/
echo ""
