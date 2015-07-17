#!/bin/bash

CUR_DIR=$(cd "$(dirname $0)" && pwd)
PARENT_DIR=$(dirname "$CUR_DIR")
DEST_DIR="$PARENT_DIR/instance"

sudo "$CUR_DIR/install.sh" --prefix="$DEST_DIR"

cd "$DEST_DIR"

sudo chown -R $USER .

rm -fr apps
ln -s "$CUR_DIR/apps" apps

rm -fr conf
ln -s "$CUR_DIR/conf" conf

rm -fr src
ln -s "$CUR_DIR/src" src

rm -fr tests
ln -s "$CUR_DIR/tests" tests

rm start_server
ln -s "$CUR_DIR/shells/start_server" start_server

rm stop_server
ln -s "$CUR_DIR/shells/stop_server" stop_server

rm check_server
ln -s "$CUR_DIR/shells/check_server" check_server

rm init.inc
rm init.lua
ln -s "$CUR_DIR/shells/init.inc" init.inc
ln -s "$CUR_DIR/shells/init.lua" init.lua
