#!/bin/bash

if [ $UID -eq 0 ]; then
    echo "Do not run this script with root user."
    exit 1
fi

function showHelp()
{
    echo "Usage: ./install_dev.sh [--prefix=absolute_path] [OPTIONS]"
    echo "Options:"
    echo -e "\t-h | --help\t\t show this help"
    echo "if the \"--prefix\" is not specified, default path is \"<PARENT_DIR>/gbc-instance\"."
}


CUR_DIR=$(cd "$(dirname $0)" && pwd)
PARENT_DIR=$(dirname "$CUR_DIR")
DEST_DIR="$PARENT_DIR/gbc-instance"

if [ $OSTYPE == "MACOS" ]; then
    gcc -o $CUR_DIR/shells/getopt_long $CUR_DIR/shells/src/getopt_long.c
    ARGS=$($CUR_DIR/shells/getopt_long "$@")
else
    ARGS=$(getopt -o h --long help,prefix: -n 'Install GameBox Cloud Core' -- "$@")
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

# cleanup
if [ -d "$DEST_DIR" ]; then
    cd "$DEST_DIR"
    rm -f apps
    rm -f conf
    rm -f src
    rm -f start_server
    rm -f stop_server
    rm -f check_server
    rm -f restart_server
    rm -f bin/shell_func.sh
    rm -f bin/shell_func.lua
fi

# install
echo "Maybe need enter your sudo password !"
echo ""
echo "sudo $CUR_DIR/install.sh --prefix=$DEST_DIR"
echo ""
sudo "$CUR_DIR/install.sh" --prefix="$DEST_DIR"

if [ ! -f "$DEST_DIR/start_server" ]; then
    exit 1
fi

# make symbol links
cd "$DEST_DIR"
sudo chown -R $USER .

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

rm restart_server
ln -s "$CUR_DIR/shells/restart_server" restart_server

rm bin/shell_func.sh
rm bin/shell_func.lua
rm bin/start_worker.lua
ln -s "$CUR_DIR/shells/shell_func.sh" bin/shell_func.sh
ln -s "$CUR_DIR/shells/shell_func.lua" bin/shell_func.lua
ln -s "$CUR_DIR/shells/start_worker.lua" bin/start_worker.lua
