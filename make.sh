#!/bin/bash

# https://pypi.python.org/pypi/virtualenv
VIRTUALENV_VER=15.0.0
# https://pypi.python.org/pypi/supervisor
SUPERVISOR_VER=3.2.2
# http://openresty.org/
OPENRESTY_VER=1.9.7.3
# http://redis.io/
REDIS_VER=3.0.7
# http://kr.github.io/beanstalkd/
BEANSTALKD_VER=1.10
# https://github.com/diegonehab/luasocket
LUASOCKET_VER=3.0-rc1
# https://github.com/cloudwu/lua-bson
LUABSON_VER=20151114
# https://github.com/cloudwu/pbc
LUAPBC_VER=20150714
# https://github.com/mah0x211/lua-process
LUAPROCESS_VER=1.5.0

function showHelp()
{
    echo "Usage: [sudo] ./make.sh [--prefix=absolute_path] [OPTIONS]"
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

# if [ $UID -ne 0 ]; then
#     echo "Superuser privileges are required to run this script."
#     echo "e.g. \"sudo $0\""
#     exit 1
# fi

OSTYPE=$(checkOSType)
SRC_DIR=$(cd "$(dirname $0)" && pwd)

echo "SRC_DIR   = $SRC_DIR"

# default configs
DEST_DIR=$SRC_DIR

if [ $OSTYPE == "MACOS" ]; then
    type "gcc" > /dev/null 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "Please install xcode."
        exit 1
    fi

    gcc -o $SRC_DIR/bin/getopt_long $SRC_DIR/bin/getopt_long.c
    ARGS=$($SRC_DIR/bin/getopt_long "$@")
else
    ARGS=$(getopt -o h --long help,prefix: -n 'Install GameBox Cloud Core' -- "$@")
fi

if [ $? -ne 0 ] ; then
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

NEED_COPY_FILES=1
if [ "$DEST_DIR" == "$SRC_DIR" ]; then
    NEED_COPY_FILES=0
fi

echo "NEED_COPY_FILES = $NEED_COPY_FILES"

mkdir -pv $DEST_DIR

if [ $? -ne 0 ]; then
    echo "DEST_DIR  = $DEST_DIR"
    echo ""
    echo "\033[31mCreate install dir failed.\033[0m"
    exit 1
fi

cd $DEST_DIR
DEST_DIR=`pwd`
echo "DEST_DIR  = $DEST_DIR"

BUILD_DIR=$DEST_DIR/tmp/install
echo "BUILD_DIR = $BUILD_DIR"
echo ""

DEST_BIN_DIR=$DEST_DIR/bin
OPENRESETY_CONFIGURE_ARGS=""

if [ $OSTYPE == "UBUNTU" ] ; then
    apt-get install -y build-essential libpcre3-dev libssl-dev git-core unzip
elif [ $OSTYPE == "CENTOS" ]; then
    yum groupinstall -y "Development Tools"
    yum install -y pcre-devel zlib-devel openssl-devel unzip
elif [ $OSTYPE == "MACOS" ]; then
    type "brew" > /dev/null 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "\033[31mPlease install brew, with this command:\033[0m"
        echo -e "\033[32mruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\" \033[0m"
        exit 0
    else
        echo ""
        echo "install pcre openssl"

        if [ $UID -eq 0 ]; then
            sudo -u $SUDO_USER brew install pcre openssl
            sudo -u $SUDO_USER brew link openssl --force
        else
            brew install pcre openssl
            brew link openssl --force
        fi

        echo ""
    fi
else
    echo "\033[31mUnsupport current OS.\033[0m"
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
cp -f $SRC_DIR/dists/*.tar.gz $BUILD_DIR

mkdir -p $DEST_DIR
mkdir -p $DEST_BIN_DIR

mkdir -p $DEST_DIR/logs
mkdir -p $DEST_DIR/tmp
mkdir -p $DEST_DIR/conf
mkdir -p $DEST_DIR/db

cd $BUILD_DIR

# ----
# install virtualenv and supervisor
echo ""
echo -e "[\033[32mINSTALL\033[0m] virtualenv"
tar xfz $SRC_DIR/dists/virtualenv-$VIRTUALENV_VER.tar.gz

PYTHON_ENV_DIR=$DEST_BIN_DIR/python_env
rm -fr $PYTHON_ENV_DIR
mv virtualenv-$VIRTUALENV_VER $PYTHON_ENV_DIR
cd $PYTHON_ENV_DIR
python virtualenv.py gbc
cd gbc
source bin/activate

echo ""
echo -e "[\033[32mINSTALL\033[0m] supervisor"
cd $BUILD_DIR
tar zxf supervisor-$SUPERVISOR_VER.tar.gz
cd supervisor-$SUPERVISOR_VER
$SED_BIN "/zip_ok = false/a\\
index-url = http://mirrors.aliyun.com/pypi/simple/" setup.cfg
python setup.py install

# ----
# install openresty and lua extensions
echo ""
echo -e "[\033[32mINSTALL\033[0m] openresty"

cd $BUILD_DIR
tar zxf openresty-$OPENRESTY_VER.tar.gz
cd openresty-$OPENRESTY_VER
mkdir -p $DEST_BIN_DIR/openresty

echo ./configure $OPENRESETY_CONFIGURE_ARGS \
    --prefix=$DEST_BIN_DIR/openresty \
    --with-luajit \
    --with-http_stub_status_module \
    --with-cc-opt="-I/usr/local/include" \
    --with-ld-opt="-L/usr/local/lib"

./configure $OPENRESETY_CONFIGURE_ARGS \
    --prefix=$DEST_BIN_DIR/openresty \
    --with-luajit \
    --with-http_stub_status_module \
    --with-cc-opt="-I/usr/local/include" \
    --with-ld-opt="-L/usr/local/lib"
make && make install
ln -f -s $DEST_BIN_DIR/openresty/luajit/bin/luajit-2.1.0-beta1 $DEST_BIN_DIR/openresty/luajit/bin/lua

# install cjson
echo ""
echo -e "[\033[32mINSTALL\033[0m] cjson"

cp -f $DEST_BIN_DIR/openresty/lualib/cjson.so $DEST_BIN_DIR/openresty/luajit/lib/lua/5.1

# install luasocket
echo ""
echo -e "[\033[32mINSTALL\033[0m] luasocket"

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
echo ""
echo -e "[\033[32mINSTALL\033[0m] luabson"

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
echo ""
echo -e "[\033[32mINSTALL\033[0m] luapbc"

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
echo ""
echo -e "[\033[32mINSTALL\033[0m] luaprocess"

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
#install redis
echo ""
echo -e "[\033[32mINSTALL\033[0m] redis"

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
echo ""
echo -e "[\033[32mINSTALL\033[0m] beanstalkd"

cd $BUILD_DIR
tar zxf beanstalkd-$BEANSTALKD_VER.tar.gz
cd beanstalkd-$BEANSTALKD_VER
mkdir -p $DEST_BIN_DIR/beanstalkd/bin

make
cp beanstalkd $DEST_BIN_DIR/beanstalkd/bin

# ----
# install apps
echo ""
echo -e "[\033[32mINSTALL\033[0m] apps"

if [ $NEED_COPY_FILES -ne 0 ]; then
    cp -rf $SRC_DIR/src $DEST_DIR
    cp -rf $SRC_DIR/apps $DEST_DIR

    cd $SRC_DIR
    cp -f start_server stop_server check_server $DEST_DIR
    cd $SRC_DIR/bin
    cp -f shell_func.sh shell_func.lua start_worker.lua getopt_long $DEST_BIN_DIR

    # copy all configuration files
    cp -f $SRC_DIR/conf/* $DEST_DIR/conf/
fi

# done
# rm -rf $BUILD_DIR

echo "DONE!"
echo ""
