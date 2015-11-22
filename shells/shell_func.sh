
function getOsType()
{
    if [ `uname -s` == "Darwin" ]; then
        echo "MACOS"
    else
        echo "LINUX"
    fi
}

function getVersion()
{
    CODE="_C=dofile('$CONF_PATH'); print('GameBox Cloud Core ' .. _GBC_CORE_VER)"
    $LUA_BIN -e "$CODE"
}

function updateConfigs()
{
    $LUA_BIN -e "ROOT_DIR='$ROOT_DIR'; _DEBUG=$DEBUG; dofile('$ROOT_DIR/bin/shell_func.lua'); updateConfigs()"
}

function startSupervisord()
{
    echo "[CMD] supervisord -c $VAR_SUPERVISORD_CONF_PATH"
    echo ""
    supervisord -c $VAR_SUPERVISORD_CONF_PATH
    echo "Start supervisord DONE"
    echo ""
}

function stopSupervisord()
{
    echo "[CMD] supervisorctl -c $VAR_SUPERVISORD_CONF_PATH shutdown"
    echo ""
    supervisorctl -c $VAR_SUPERVISORD_CONF_PATH shutdown
    echo ""
}

function restartSupervisord()
{
    echo "[CMD] supervisorctl -c $VAR_SUPERVISORD_CONF_PATH restart all"
    echo ""
    supervisorctl -c $VAR_SUPERVISORD_CONF_PATH restart all
    echo "Restart supervisord DONE"
    echo ""
}

function checkStatus()
{
    supervisorctl -c $VAR_SUPERVISORD_CONF_PATH status
    echo ""
}

# set env

if [ "$1" != "quiet" ]; then
    echo -e "\033[31mROOT_DIR\033[0m=$ROOT_DIR"
    echo ""
fi

cd $ROOT_DIR

LUA_BIN=$ROOT_DIR/bin/openresty/luajit/bin/lua
TMP_DIR=$ROOT_DIR/tmp
CONF_DIR=$ROOT_DIR/conf
CONF_PATH=$CONF_DIR/config.lua
VAR_SUPERVISORD_CONF_PATH=$TMP_DIR/supervisord.conf

VERSION=$(getVersion)
OS_TYPE=$(getOsType)
if [ $OS_TYPE == "MACOS" ]; then
    SED_BIN='sed -i --'
else
    SED_BIN='sed -i'
fi

