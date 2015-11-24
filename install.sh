#!/bin/bash

function showHelp()
{
    echo "Usage: [sudo] ./install.sh [--prefix=absolute_path] [OPTIONS]"
    echo "Options:"
    echo -e "\t-h | --help\t\t show this help"
    echo "if the \"--prefix\" is not specified, default path is \"/opt/gbc-core\"."
}

function checkOSType()
{
    type "apt-get" > /dev/null 2> /dev/null
    if [ $? -eq 0 ]; then
        echo "UBUNTU"
        exit 0
    fi

    type "yum" > /dev/null 2> /dev/null
    if [ $? -eq 0 ]; then
        echo "CENTOS"
        exit 0
    fi

    RES=$(uname -s)
    if [ $RES == "Darwin" ]; then
        echo "MACOS"
        exit 0
    fi

    echo "UNKNOW"
    exit 1
}

if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

OSTYPE=$(checkOSType)
CUR_DIR=$(cd "$(dirname $0)" && pwd)
BUILD_DIR=/tmp/install-gbc-core
DEST_DIR=/opt/gbc-core

# dists
OPENRESTY_VER=1.9.3.1-luajit-2.1-beta1
REDIS_VER=3.0.5
BEANSTALKD_VER=1.10
SUPERVISOR_VER=3.1.3

# https://github.com/diegonehab/luasocket
LUASOCKET_VER=3.0-rc1
# https://github.com/cloudwu/lua-bson
LUABSON_VER=20151114
# https://github.com/cloudwu/pbc
LUAPBC_VER=20150714
# https://github.com/mah0x211/lua-process
LUAPROCESS_VER=1.5.0

if [ $OSTYPE == "MACOS" ]; then
    gcc -o $CUR_DIR/shells/getopt_long $CUR_DIR/shells/src/getopt_long.c
    ARGS=$($CUR_DIR/shells/getopt_long "$@")
else
    ARGS=$(getopt -o h --long help,prefix: -n 'Install GameBox Cloud Core' -- "$@")
fi

if [ $? != 0 ] ; then
    echo "Install GameBox Cloud Core Terminating..." >&2;
    exit 1;
fi

eval set -- "$ARGS"

while true ; do
    case "$1" in
        --prefix)
            DEST_DIR=$2
            shift 2
            ;;

        -h|--help)
            showHelp;
            exit 0
            ;;

        --)
            shift;
            break
            ;;

        *)
            echo "invalid option: $1"
            exit 1
            ;;
    esac
done

DEST_BIN_DIR=$DEST_DIR/bin
OPENRESETY_CONFIGURE_ARGS=""

if [ $OSTYPE == "UBUNTU" ] ; then
    apt-get install -y build-essential libpcre3-dev libssl-dev git-core unzip supervisor
elif [ $OSTYPE == "CENTOS" ]; then
    yum groupinstall -y "Development Tools"
    yum install -y pcre-devel zlib-devel openssl-devel unzip supervisor
elif [ $OSTYPE == "MACOS" ]; then
    type "brew" > /dev/null 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "Please install brew, with this command:"
        echo -e "\033[33mruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\" \033[0m"
        exit 0
    else
        sudo -u $SUDO_USER brew install pcre
    fi

    OPENRESETY_CONFIGURE_ARGS="--without-http_ssl_module --without-http_encrypted_session_module"

    type "gcc" > /dev/null 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "Please install xcode."
        exit 0
    fi
else
    echo "Unsupport current OS."
    exit 1
fi

if [ $OSTYPE == "MACOS" ]; then
    SED_BIN='sed -i --'
else
    SED_BIN='sed -i'
fi

set -e

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cp -f $CUR_DIR/dists/*.tar.gz $BUILD_DIR

mkdir -p $DEST_DIR
mkdir -p $DEST_BIN_DIR

mkdir -p $DEST_DIR/logs
mkdir -p $DEST_DIR/tmp
mkdir -p $DEST_DIR/conf
mkdir -p $DEST_DIR/db

# ----
# install openresty and lua extensions
cd $BUILD_DIR
tar zxf ngx_openresty-$OPENRESTY_VER.tar.gz
cd ngx_openresty-$OPENRESTY_VER
mkdir -p $DEST_BIN_DIR/openresty

./configure $OPENRESETY_CONFIGURE_ARGS \
    --prefix=$DEST_BIN_DIR/openresty \
    --with-luajit \
    --with-http_stub_status_module \
    --with-cc-opt="-I/usr/local/include" \
    --with-ld-opt="-L/usr/local/lib"
make && make install
ln -f -s $DEST_BIN_DIR/openresty/luajit/bin/luajit-2.1.0-beta1 $DEST_BIN_DIR/openresty/luajit/bin/lua

# install cjson
cp -f $DEST_BIN_DIR/openresty/lualib/cjson.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1

# install luasocket
cd $BUILD_DIR
tar zxf luasocket-$LUASOCKET_VER.tar.gz
cd luasocket-$LUASOCKET_VER
if [ $OSTYPE == "MACOS" ]; then
    $SED_BIN "s#PLAT?= linux#PLAT?= macosx#g" makefile
    $SED_BIN "s#PLAT?=linux#PLAT?=macosx#g" src/makefile
    $SED_BIN "s#LUAPREFIX_macosx?=/opt/local#LUAPREFIX_macosx?=$DEST_BIN_DIR/openresty/luajit#g" src/makefile
    $SED_BIN "s#LUAINC_macosx_base?=/opt/local/include#LUAINC_macosx_base?=$DEST_BIN_DIR/openresty/luajit/include#g" src/makefile
    $SED_BIN "s#\$(LUAINC_macosx_base)/lua/\$(LUAV)#\$(LUAINC_macosx_base)/luajit-2.1#g" src/makefile
else
    $SED_BIN "s#LUAPREFIX_linux?=/usr/local#LUAPREFIX_linux?=$DEST_BIN_DIR/openresty/luajit#g" src/makefile
    $SED_BIN "s#LUAINC_linux_base?=/usr/include#LUAINC_linux_base?=$DEST_BIN_DIR/openresty/luajit/include#g" src/makefile
    $SED_BIN "s#\$(LUAINC_linux_base)/lua/\$(LUAV)#\$(LUAINC_linux_base)/luajit-2.1#g" src/makefile
fi
make && make install-unix
cp -f src/serial.so src/unix.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1/socket/.

# install luabson
cd $BUILD_DIR
tar zxf luabson-$LUABSON_VER.tar.gz
cd lua-bson
if [ $OSTYPE == "MACOS" ]; then
    $SED_BIN "s#-I/usr/local/include -L/usr/local/bin -llua53#-I$DEST_BIN_DIR/openresty/luajit/include/luajit-2.1 -L$DEST_BIN_DIR/openresty/luajit/lib -lluajit-5.1#g" Makefile
else
    $SED_BIN "s#-I/usr/local/include -L/usr/local/bin -llua53#-I$DEST_BIN_DIR/openresty/luajit/include/luajit-2.1 -L$DEST_BIN_DIR/openresty/luajit/lib#g" Makefile
fi
make linux

cp -f bson.so $DEST_BIN_DIR/openresty/lualib
cp -f bson.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1

#install luapbc
cd $BUILD_DIR
tar zxf luapbc-$LUAPBC_VER.tar.gz
cd pbc
make lib
cd binding/lua
if [ $OSTYPE == "MACOS" ]; then
    $SED_BIN "s#/usr/local/include#$DEST_BIN_DIR/openresty/luajit/include/luajit-2.1 -L$DEST_BIN_DIR/openresty/luajit/lib -lluajit-5.1#g" Makefile
else
    $SED_BIN "s#/usr/local/include#$DEST_BIN_DIR/openresty/luajit/include/luajit-2.1#g" Makefile
fi
make

cp -f protobuf.so $DEST_BIN_DIR/openresty/lualib
cp -f protobuf.lua $DEST_BIN_DIR/openresty/lualib

cp -f protobuf.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1
cp -f protobuf.lua $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1

# install luaprocess
cd $BUILD_DIR
tar zxf lua-process-$LUAPROCESS_VER.tar.gz
cd lua-process-$LUAPROCESS_VER
cp Makefile Makefile_
echo "PACKAGE=process" > Makefile
echo "LIB_EXTENSION=so" >> Makefile
echo "SRCDIR=src" >> Makefile
echo "TMPLDIR=tmpl" >> Makefile
echo "VARDIR=var" >> Makefile
echo "CFLAGS=-Wall -fPIC -O2 -I_GBC_CORE_ROOT_/bin/openresty/luajit/include/luajit-2.1" >> Makefile
echo "LDFLAGS=--shared -Wall -fPIC -O2 -L_GBC_CORE_ROOT_/bin/openresty/luajit/lib" >> Makefile
if [ $OSTYPE == "MACOS" ]; then
    echo "LIBS=-lluajit-5.1" >> Makefile
fi
echo "" >> Makefile
cat Makefile_ >> Makefile
rm Makefile_

$SED_BIN "s#_GBC_CORE_ROOT_#$DEST_DIR#g" Makefile
$SED_BIN "s#lua ./codegen.lua#$DEST_BIN_DIR/openresty/luajit/bin/lua ./codegen.lua#g" Makefile

make

cp -f process.so $DEST_BIN_DIR/openresty/lualib
cp -f process.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1

# ----
# install supervisor
if [ $OSTYPE == "MACOS" ]; then
    cd $BUILD_DIR
    tar zxf supervisor-$SUPERVISOR_VER.tar.gz
    cd supervisor-$SUPERVISOR_VER
    python setup.py install
fi

# ----
#install redis
cd $BUILD_DIR
tar zxf redis-$REDIS_VER.tar.gz
cd redis-$REDIS_VER
mkdir -p $DEST_BIN_DIR/redis/bin

make
cp src/redis-server $DEST_BIN_DIR/redis/bin
cp src/redis-cli $DEST_BIN_DIR/redis/bin
cp src/redis-sentinel $DEST_BIN_DIR/redis/bin
cp src/redis-benchmark $DEST_BIN_DIR/redis/bin
cp src/redis-check-aof $DEST_BIN_DIR/redis/bin
cp src/redis-check-dump $DEST_BIN_DIR/redis/bin

# ----
# install beanstalkd
cd $BUILD_DIR
tar zxf beanstalkd-$BEANSTALKD_VER.tar.gz
cd beanstalkd-$BEANSTALKD_VER
mkdir -p $DEST_BIN_DIR/beanstalkd/bin

make
cp beanstalkd $DEST_BIN_DIR/beanstalkd/bin

# ----
# install apps
cp -rf $CUR_DIR/src $DEST_DIR
cp -rf $CUR_DIR/apps $DEST_DIR

cd $CUR_DIR/shells/
cp -f start_server stop_server check_server restart_server $DEST_DIR
cp -f shell_func.sh shell_func.lua start_worker.lua $DEST_BIN_DIR

# if it in Mac OS X, getopt_long should be deployed.
if [ $OSTYPE == "MACOS" ]; then
    cp -f $CUR_DIR/shells/getopt_long $DEST_DIR/bin
    rm $CUR_DIR/shells/getopt_long
fi

# copy all configuration files
cp -f $CUR_DIR/conf/* $DEST_DIR/conf/

# done

echo ""
echo ""
echo ""
echo "DONE!"
echo ""
echo ""
