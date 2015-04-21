#!/bin/bash

function getVersion()
{
    LUABIN=$1/bin/openresty/luajit/bin/lua
    CODE='_C=require("conf.config"); print("Quick Server " .. _QUICK_SERVER_VERSION);'

    $LUABIN -e "$CODE"
}

OLDDIR=$(pwd)
CURRDIR=$(cd "$(dirname $0)" && pwd)

cd $CURRDIR
VERSION=$(getVersion $CURRDIR)

grep "_DBG_DEBUG" $CURRDIR/bin/instrument/start_workers.sh > /dev/null

if [ $? -ne 0 ]; then
    echo -e "\n$VERSION in \033[32mRELEASE\033[0m mode"
else
    echo -e "\n$VERSION in \033[31mDEBUG\033[0m mode"
fi


echo -e "\n\033[33m[Nginx] \033[0m"
ps -ef | grep -i "nginx" | grep -v "grep" --color=auto

echo -e "\n\033[33m[Redis] \033[0m"
ps -ef | grep -i "redis" | grep -v "grep" --color=auto

echo -e "\n\033[33m[Beanstalkd] \033[0m"
ps -ef | grep -i "beanstalkd" | grep -v "grep" --color=auto

echo -e "\n\033[33m[Monitor] \033[0m"
ps -ef | grep -i "monitor\.sh" | grep -v "grep" --color=auto | grep -v "lua -e SERVER_CONFIG" --color=auto

echo -e "\n\033[33m[Job Worker] \033[0m"
ps -ef | grep -i "start_workers\.sh" | grep -v "grep" --color=auto | grep -v "lua -e SERVER_CONFIG" --color=auto

echo ""

cd $OLDDIR
