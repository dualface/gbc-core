#!/bin/bash

if [ $UID -eq 0 ]; then
    echo "Do not run this script with root user."
    exit 1
fi

CUR_DIR=$(cd "$(dirname $0)" && pwd)
PARENT_DIR=$(dirname "$CUR_DIR")
DEST_DIR="$PARENT_DIR/gbc-instance"

if [ -d "$DEST_DIR" ]; then
    cd "$DEST_DIR"
    rm -f apps
    rm -f conf
    rm -f src
    rm -f tests
    rm -f start_server
    rm -f stop_server
    rm -f check_server
    rm -f restart_server
    rm -f bin/init.inc
    rm -f bin/init.lua
fi

echo "Maybe need enter your sudo password !"
echo ""
echo "sudo $CUR_DIR/install.sh --prefix=$DEST_DIR"
echo ""
sudo "$CUR_DIR/install.sh" --prefix="$DEST_DIR"

if [ !-f "$DEST_DIR/start_server" ]; then
    exit 1
fi

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

rm restart_server
ln -s "$CUR_DIR/shells/restart_server" restart_server

rm bin/init.inc
rm bin/init.lua
ln -s "$CUR_DIR/shells/init.inc" bin/init.inc
ln -s "$CUR_DIR/shells/init.lua" bin/init.lua

