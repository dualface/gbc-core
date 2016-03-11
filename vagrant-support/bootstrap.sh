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

    # fix locale warnings
    apt-get install -y language-pack-en
    echo "" >> /home/vagrant/.profile
    echo "export LC_CTYPE=\"en_US.UTF-8\"" >> /home/vagrant/.profile
    echo "export LANG=\"en_US.UTF-8\"" >> /home/vagrant/.profile
    chown vagrant:vagrant /home/vagrant/.profile

    export LC_CTYPE="en_US.UTF-8"
    export LANG="en_US.UTF-8"

    cd /vagrant/
    sudo ./install.sh

    sudo rm -fr /opt/gbc-core/apps
    sudo rm -fr /opt/gbc-core/conf
    sudo rm -fr /opt/gbc-core/src

    sudo rm -f /opt/gbc-core/start_server
    sudo rm -f /opt/gbc-core/stop_server
    sudo rm -f /opt/gbc-core/check_server

    sudo rm -f /opt/gbc-core/bin/start_worker.lua
    sudo rm -f /opt/gbc-core/bin/shell_func.sh
    sudo rm -f /opt/gbc-core/bin/shell_func.lua

    ln -s /vagrant/apps /opt/gbc-core/apps
    ln -s /vagrant/conf /opt/gbc-core/conf
    ln -s /vagrant/src  /opt/gbc-core/src

    ln -s /vagrant/shells/start_server /opt/gbc-core/start_server
    ln -s /vagrant/shells/stop_server  /opt/gbc-core/stop_server
    ln -s /vagrant/shells/check_server /opt/gbc-core/check_server

    ln -s /vagrant/shells/start_worker.lua /opt/gbc-core/bin/start_worker.lua
    ln -s /vagrant/shells/shell_func.sh    /opt/gbc-core/bin/shell_func.sh
    ln -s /vagrant/shells/shell_func.lua   /opt/gbc-core/bin/shell_func.lua

    echo ""
    ls -lh /opt/gbc-core

    echo ""
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
