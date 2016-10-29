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
    apt-get install -y mysql-server mysql-client python-minimal

    # fix locale warnings
    apt-get install -y language-pack-en
    echo "" >> /home/vagrant/.profile
    echo "export LC_CTYPE=\"en_US.UTF-8\"" >> /home/vagrant/.profile
    echo "export LANG=\"en_US.UTF-8\"" >> /home/vagrant/.profile
    chown vagrant:vagrant /home/vagrant/.profile

    export LC_CTYPE="en_US.UTF-8"
    export LANG="en_US.UTF-8"

    cd /vagrant/
    ./make.sh --prefix=/opt/gbc-core

    rm -fr /opt/gbc-core/apps
    rm -fr /opt/gbc-core/conf
    rm -fr /opt/gbc-core/src

    rm -f /opt/gbc-core/start_server
    rm -f /opt/gbc-core/stop_server
    rm -f /opt/gbc-core/check_server
    rm -f /opt/gbc-core/restart_server

    rm -f /opt/gbc-core/bin/start_worker.lua
    rm -f /opt/gbc-core/bin/shell_func.sh
    rm -f /opt/gbc-core/bin/shell_func.lua

    ln -s /vagrant/apps /opt/gbc-core/apps
    ln -s /vagrant/conf /opt/gbc-core/conf
    ln -s /vagrant/src  /opt/gbc-core/src

    ln -s /vagrant/start_server /opt/gbc-core/start_server
    ln -s /vagrant/stop_server  /opt/gbc-core/stop_server
    ln -s /vagrant/check_server /opt/gbc-core/check_server
    ln -s /vagrant/restart_server /opt/gbc-core/restart_server

    ln -s /vagrant/bin/start_worker.lua /opt/gbc-core/bin/start_worker.lua
    ln -s /vagrant/bin/shell_func.sh    /opt/gbc-core/bin/shell_func.sh
    ln -s /vagrant/bin/shell_func.lua   /opt/gbc-core/bin/shell_func.lua

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
echo ""
echo ALL DONE. please use browser open http://localhost:8088/
echo ""

