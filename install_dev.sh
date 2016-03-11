#!/bin/bash

CUR_DIR=$(cd "$(dirname $0)" && pwd)
DEST_DIR="$CUR_DIR/devel"

# cleanup
if [ -d "$DEST_DIR" ]; then
    cd "$DEST_DIR"
    rm -f apps
    rm -f conf
    rm -f src
    rm -f start_server
    rm -f stop_server
    rm -f check_server
    rm -f bin/start_worker.lua
    rm -f bin/shell_func.sh
    rm -f bin/shell_func.lua
fi

# install
echo ""
echo "$CUR_DIR/install.sh --prefix=$DEST_DIR"
echo ""
"$CUR_DIR/install.sh" --prefix="$DEST_DIR"

if [ ! -f "$DEST_DIR/start_server" ]; then
    exit 1
fi

# make symbol links
cd "$DEST_DIR"

rm -fr apps
ln -s "$CUR_DIR/apps" apps

rm -fr conf
ln -s "$CUR_DIR/conf" conf

rm -fr src
ln -s "$CUR_DIR/src" src

rm start_server
ln -s "$CUR_DIR/shells/start_server" start_server

rm stop_server
ln -s "$CUR_DIR/shells/stop_server" stop_server

rm check_server
ln -s "$CUR_DIR/shells/check_server" check_server

rm bin/shell_func.sh
rm bin/shell_func.lua
rm bin/start_worker.lua
ln -s "$CUR_DIR/shells/shell_func.sh" bin/shell_func.sh
ln -s "$CUR_DIR/shells/shell_func.lua" bin/shell_func.lua
ln -s "$CUR_DIR/shells/start_worker.lua" bin/start_worker.lua
