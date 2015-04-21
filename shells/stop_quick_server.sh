#!/bin/bash

function showHelp()
{
    echo "Usage: [sudo] ./stop_quick_server.sh [OPTIONS] [--reload]"
    echo "Options:"
    echo -e "\t -a , --all \t\t stop nginx, redis and beanstalkd"
    echo -e "\t -n , --nginx \t\t stop nginx"
    echo -e "\t -r , --redis \t\t stop redis"
    echo -e "\t -b , --beanstalkd \t stop beanstalkd"
    echo -e "\t -h , --help \t\t show this help"
    echo -e "\t -v , --version \t\t show version"
    echo -e "\t      --reload \t\t reload Quick Server config."
    echo "if the option is not specified, default option is \"--all(-a)\"."
}

function getVersion()
{
    LUABIN=$1/bin/openresty/luajit/bin/lua
    CODE='_C=require("conf.config"); print("Quick Server " .. _QUICK_SERVER_VERSION);'

    $LUABIN -e "$CODE"
}

function getNginxNumOfWorker()
{
    LUABIN=$1/bin/openresty/luajit/bin/lua
    CODE="_C=require([[conf.config]]); print(_C.numOfWorkers);"

    $LUABIN -e "$CODE"
}

function getNginxPort()
{
    LUABIN=$1/bin/openresty/luajit/bin/lua
    CODE="_C=require([[conf.config]]); print(_C.port);"

    $LUABIN -e "$CODE"
}

function isMacOs()
{
    TMPRES=$(uname -s)
    if [ $TMPRES == "Darwin" ]; then
        echo "MACOS"
        exit 0
    fi

    echo "LINUX"
}

OLDDIR=$(pwd)
CURRDIR=$(cd "$(dirname $0)" && pwd)
NGINXDIR=$CURRDIR/bin/openresty/nginx/

cd $CURRDIR
VERSION=$(getVersion $CURRDIR)

OSTYPE=$(isMacOs)
if [ $OSTYPE == "MACOS" ]; then
    SED_BIN='sed -i --'
    ARGS=$($CURRDIR/tmp/getopt_long "$@")
else
    SED_BIN='sed -i'
    ARGS=$(getopt -o abrnvh --long all,nginx,redis,beanstalkd,reload,version,help -n 'Stop quick server' -- "$@")
fi

if [ $? != 0 ] ; then echo "Stop Quick Server Terminating..." >&2; exit 1; fi

eval set -- "$ARGS"

declare -i RELOAD=0
declare -i ALL=0
declare -i BEANS=0
declare -i NGINX=0
declare -i REDIS=0
if [ $# -eq 1 ] ; then
    ALL=1
fi

while true ; do
    case "$1" in
        --reload)
            RELOAD=1
            shift
            ;;

        -a|--all)
            ALL=1
            shift
            ;;

        -b|--beanstalkd)
            BEANS=1
            shift
            ;;

        -r|--redis)
            REDIS=1
            shift
            ;;

        -n|--nginx)
            NGINX=1
            shift
            ;;

        -v|--version)
            echo $VERSION
            exit 0
            ;;

        -h|--help)
            showHelp;
            exit 0
            ;;

        --) shift; break ;;

        *)
            echo "invalid option. $1"
            exit 1
            ;;
    esac
done

# "--reload" option has no effect on other options, except "--ngxin(-n)".
if [ $RELOAD -ne 0 ]; then
    ALL=0
fi

# stop monitor and job worker first.
if [ $OSTYPE == "MACOS" ]; then
    ps -ef | grep "start_workers" | awk '{print $2}' | xargs kill -9 > /dev/null 2> /dev/null
    ps -ef | grep "monitor" | awk '{print $2}' | xargs kill -9 > /dev/null 2> /dev/null
else
    killall start_workers.sh > /dev/null 2> /dev/null
    killall monitor.sh > /dev/null 2> /dev/null
fi
killall $CURRDIR/bin/openresty/luajit/bin/lua > /dev/null 2> /dev/null

#stop nginx
if [ $ALL -eq 1 ] || [ $NGINX -eq 1 ] || [ $RELOAD -eq 1 ]; then
    if [ $RELOAD -eq 0 ] ; then
        pgrep nginx > /dev/null
        if [ $? -eq 0 ]; then
            nginx -q -p $CURRDIR -c $NGINXDIR/conf/nginx.conf -s stop
            if [ $? -ne 0 ]; then
                exit $?
            fi
        fi

        sleep 1
        echo "Stop Nginx DONE"
    else
        PORT=$(getNginxPort $CURRDIR)
        $SED_BIN "s#listen [0-9]*#listen $PORT#g" $NGINXDIR/conf/nginx.conf

        NUMOFWORKERS=$(getNginxNumOfWorker $CURRDIR)
        $SED_BIN "s#worker_processes [0-9]*#worker_processes $NUMOFWORKERS#g" $NGINXDIR/conf/nginx.conf

        rm -f $NGINXDIR/conf/nginx.conf--

        nginx -p $CURRDIR -c $NGINXDIR/conf/nginx.conf -s reload
        if [ $? -ne 0 ]; then
            exit $?
        fi
        echo "Reload Nginx conf DONE"
    fi
fi

#stop redis
if [ $ALL -eq 1 ] || [ $REDIS -eq 1 ]; then
    pgrep nginx > /dev/null

    while [ $? -eq 0 ];
    do
        nginx -q -p $CURRDIR -c $NGINXDIR/conf/nginx.conf -s stop
        pgrep nginx > /dev/null
    done

    killall redis-server 2> /dev/null
    echo "Stop Redis DONE"
fi

#stop beanstalkd
if [ $ALL -eq 1 ] || [ $BEANS -eq 1 ]; then
    killall beanstalkd 2> /dev/null
    echo "Stop Beanstalkd DONE"
fi


if [ $RELOAD -ne 0 ]; then
    if [ $OSTYPE != "MACOS" ]; then
        $CURRDIR/bin/instrument/monitor.sh > $CURRDIR/logs/monitor.log &
    fi

    # start job worker
    I=0
    rm -f $CURRDIR/logs/jobworker.log
    while [ $I -lt $NUMOFWORKERS ]; do
        $CURRDIR/bin/instrument/start_workers.sh >> $CURRDIR/logs/jobworker.log &
        I=$((I+1))
    done
fi

if [ $ALL -eq 1 ] ; then
    echo -e "\033[33mStop $VERSION DONE! \033[0m"
    echo "Stop $VERSION DONE!" >> $CURRDIR/logs/error.log
fi

sleep 3
$CURRDIR/status_quick_server.sh

cd $OLDDIR
