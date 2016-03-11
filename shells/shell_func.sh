#/bin/bash

if [ "$ROOT_DIR" == "" ]; then
    echo "Not set ROOT_DIR, exit."
    exit 1
fi

echo -e "\033[31mROOT_DIR\033[0m=$ROOT_DIR"
echo ""

cd $ROOT_DIR

LUA_BIN=$ROOT_DIR/bin/openresty/luajit/bin/lua
TMP_DIR=$ROOT_DIR/tmp
CONF_DIR=$ROOT_DIR/conf
CONF_PATH=$CONF_DIR/config.lua
VAR_SUPERVISORD_CONF_PATH=$TMP_DIR/supervisord.conf

function getOsType()
{
    if [ `uname -s` == "Darwin" ]; then
        echo "MACOS"
    else
        echo "LINUX"
    fi
}

OS_TYPE=$(getOsType)
if [ $OS_TYPE == "MACOS" ]; then
    SED_BIN='sed -i --'
else
    SED_BIN='sed -i'
fi

function updateConfigs()
{
    $LUA_BIN -e "ROOT_DIR='$ROOT_DIR'; DEBUG=$DEBUG; dofile('$ROOT_DIR/bin/shell_func.lua'); updateConfigs()"
}

function startSupervisord()
{
    echo "[CMD] supervisord -c $VAR_SUPERVISORD_CONF_PATH"
    echo ""
    cd $ROOT_DIR/bin/python_env/gbc
    source bin/activate
    $ROOT_DIR/bin/python_env/gbc/bin/supervisord -c $VAR_SUPERVISORD_CONF_PATH
    cd $ROOT_DIR
    echo "Start supervisord DONE"
    echo ""
}

function stopSupervisord()
{
    echo "[CMD] supervisorctl -c $VAR_SUPERVISORD_CONF_PATH shutdown"
    echo ""
    cd $ROOT_DIR/bin/python_env/gbc
    source bin/activate
    $ROOT_DIR/bin/python_env/gbc/bin/supervisorctl -c $VAR_SUPERVISORD_CONF_PATH shutdown
    cd $ROOT_DIR
    echo ""
}

function checkStatus()
{
    supervisorctl -c $VAR_SUPERVISORD_CONF_PATH status
    echo ""
}
