#!/bin/bash

CUR_DIR=$(cd "$(dirname $0)" && pwd)
PARENT_DIR=`dirname "$CUR_DIR"`
DEST_DIR=$PARENT_DIR/instance

sudo $CUR_DIR/install.sh --prefix=$DEST_DIR

cd $DEST_DIR

sudo chown -R $USER .

rm -fr apps
ln -s ../core/apps apps

rm -fr conf
ln -s ../core/conf conf

rm -fr src
ln -s ../core/src src

rm start_server
ln -s ../core/shells/start_server start_server

rm stop_server
ln -s ../core/shells/stop_server stop_server

rm check_server
ln -s ../core/shells/check_server check_server

rm init.inc
rm init.lua
ln -s ../core/shells/init.inc init.inc
ln -s ../core/shells/init.lua init.lua

