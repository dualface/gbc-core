
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
    CODE="_C=loadfile('$CONF_PATH')(); print('GameBox Cloud Core ' .. _GBC_CORE_VER)"
    $LUA_BIN -e "$CODE"
}

function updateConfig()
{
    $LUA_BIN -e "ROOT_DIR='$ROOT_DIR'; _DEBUG=$DEBUG; loadfile('$ROOT_DIR/init.lua')(); updateConfig()"
}

function updateNginxConf()
{
    $LUA_BIN -e "ROOT_DIR='$ROOT_DIR'; _DEBUG=$DEBUG; loadfile('$ROOT_DIR/init.lua')(); updateNginxConfig()"
}

function updateRedisConf()
{
    $LUA_BIN -e "ROOT_DIR='$ROOT_DIR'; _DEBUG=$DEBUG; loadfile('$ROOT_DIR/init.lua')(); updateRedisConfig()"
}

function updateAllConfigs()
{
    updateConfig
    updateNginxConf
    updateRedisConf
}

function getRedisArgs()
{
    $LUA_BIN -e "ROOT_DIR='$ROOT_DIR'; _DEBUG=$DEBUG; loadfile('$ROOT_DIR/init.lua')(); print(getRedisArgs())"
}

function getBeanstalkdArgs()
{
    $LUA_BIN -e "ROOT_DIR='$ROOT_DIR'; _DEBUG=$DEBUG; loadfile('$ROOT_DIR/init.lua')(); print(getBeanstalkdArgs())"
}

# --

function startNginx()
{
    pgrep nginx > /dev/null
    if [ $? -ne 0 ]; then
        echo "[CMD] nginx -p $ROOT_DIR -c $VAR_NGINX_CONF_PATH"
        $NGINX_DIR/sbin/nginx -p $ROOT_DIR -c $VAR_NGINX_CONF_PATH
        if [ $? -ne 0 ]; then
            exit $?
        fi
        echo "Start Nginx DONE"
    else
        echo "Nginx is already started"
    fi
    echo ""
}

function stopNginx()
{
    pgrep nginx > /dev/null
    if [ $? -eq 0 ]; then
        echo "[CMD] nginx -p $ROOT_DIR -c $VAR_NGINX_CONF_PATH -s stop"
        $NGINX_DIR/sbin/nginx -p $ROOT_DIR -c $VAR_NGINX_CONF_PATH -s stop
        if [ $? -ne 0 ]; then
            exit $?
        fi
        echo "Stop Nginx DONE"
    else
        echo "Nginx is not running"
    fi
    echo ""
}

function reloadNginx()
{
    pgrep nginx > /dev/null
    if [ $? -eq 0 ]; then
        echo "[CMD] nginx -p $ROOT_DIR -c $VAR_NGINX_CONF_PATH -s reload"
        $NGINX_DIR/sbin/nginx -p $ROOT_DIR -c $VAR_NGINX_CONF_PATH -s reload
        if [ $? -ne 0 ]; then
            exit $?
        fi
        echo "Reload Nginx DONE"
    else
        echo "Nginx is not running"
    fi
    echo ""
}

# --

function startRedis()
{
    pgrep redis-server > /dev/null
    if [ $? -ne 0 ]; then
        echo "[CMD] redis-server $VAR_REDIS_CONF_PATH"
        $REDIS_DIR/bin/redis-server $VAR_REDIS_CONF_PATH
        if [ $? -ne 0 ]; then
            exit $?
        fi
        echo "Start Redis DONE"
    else
        echo "Redis is already started"
    fi
    echo ""
}

function stopRedis()
{
    # check redis process
    pgrep redis-server > /dev/null
    if [ $? -eq 0 ]; then
        REDIS_ARGS=$(getRedisArgs)
        echo "[CMD] redis-cli $REDIS_ARGS SHUTDOWN SAVE"
        $REDIS_DIR/bin/redis-cli $REDIS_ARGS SHUTDOWN SAVE
        echo "Stop Redis DONE"
    else
        echo "Redis is not running"
    fi
    echo ""
}

# --

function startBeanstalkd()
{
    pgrep beanstalkd > /dev/null
    if [ $? -ne 0 ]; then
        BEANS_ARGS=$(getBeanstalkdArgs)
        echo "[CMD] beanstalkd $BEANS_ARGS"
        $ROOT_DIR/bin/beanstalkd/bin/beanstalkd $BEANS_ARGS > $VAR_BEANS_LOG_PATH &
        if [ $? -ne 0 ]; then
            exit $?
        fi
        echo "Start Beanstalkd DONE"
    else
        echo "Beanstalkd is already started"
    fi
    echo ""
}

function stopBeanstalkd()
{
    BEANS_PID=`pgrep beanstalkd`
    if [ $? -eq 0 ]; then
        echo "[CMD] kill $BEANS_PID"
        kill $BEANS_PID
        echo "Stop Beanstalkd DONE"
    else
        echo "Beanstalkd is not running"
    fi
    echo ""
}

# --

function startJobWorkers()
{
    # ps -ef | grep -i "start_workers.*sh" | grep -v "grep" > /dev/null
    # if [ $? -ne 0 ]; then
    #     I=0
    #     rm -f $ROOT_DIR/logs/jobworker.log
    #     BEANS_NUM_OF_WORKERS=$(getBeanstalkdNumOfWorker)
    #     while [ $I -lt $BEANS_NUM_OF_WORKERS ]; do
    #         $ROOT_DIR/bin/instrument/start_workers.sh >> $ROOT_DIR/logs/jobworker.log &
    #         I=$((I+1))
    #     done
    #     echo "Start Job Workers DONE"
    # else
    #     echo "Job Workers is already started"
    # fi
    echo ""
}

function stopJobWorkers()
{
    # echo "[CMD] killall start_workers.sh"
    # if [ $OS_TYPE == "MACOS" ]; then
    #     ps -ef | grep "start_workers" | awk '{print $2}' | xargs kill -9 > /dev/null 2> /dev/null
    # else
    #     killall start_workers.sh > /dev/null 2> /dev/null
    # fi
    # echo "[CMD] killall $CURRDIR/bin/openresty/luajit/bin/lua"
    # killall -KILL $CURRDIR/bin/openresty/luajit/bin/lua > /dev/null 2> /dev/null
    # echo "Stop Job Workers DONE"
    echo ""
}

# --

function startMonitor()
{
    if [ $OS_TYPE != "MACOS" ]; then
        ps -ef | grep -i "monitor.*sh" | grep -v "grep" > /dev/null
        if [ $? -ne 0 ]; then
            $ROOT_DIR/bin/instrument/monitor.sh > $ROOT_DIR/logs/monitor.log &
        fi
    fi
}

function stopMonitor()
{
    if [ $OS_TYPE == "MACOS" ]; then
        ps -ef | grep "monitor" | awk '{print $2}' | xargs kill -9 > /dev/null 2> /dev/null
    else
        killall monitor.sh > /dev/null 2> /dev/null
    fi
}

# --

function checkStatus()
{
    if [ -f "$VAR_NGINX_CONF_PATH" ]; then
        grep "_DBG_DEBUG" $VAR_NGINX_CONF_PATH > /dev/null
        if [ $? -ne 0 ]; then
            DEBUG=0
            echo -e "$VERSION in \033[32mRELEASE\033[0m mode"
        else
            DEBUG=1
            echo -e "$VERSION in \033[31mDEBUG\033[0m mode"
        fi
        echo ""
    fi

    echo -e "\033[33m[Nginx] \033[0m"
    ps -ef | grep -i "nginx" | grep -v "grep" --color=auto
    echo ""

    echo -e "\033[33m[Redis] \033[0m"
    ps -ef | grep -i "redis" | grep -v "grep" --color=auto
    echo ""

    echo -e "\033[33m[Beanstalkd] \033[0m"
    ps -ef | grep -i "beanstalkd" | grep -v "grep" --color=auto
    echo ""

    echo -e "\033[33m[Monitor] \033[0m"
    ps -ef | grep -i "monitor\.sh" | grep -v "grep" --color=auto | grep -v "lua -e SERVER_CONFIG" --color=auto
    echo ""

    echo -e "\033[33m[Job Worker] \033[0m"
    ps -ef | grep -i "start_workers\.sh" | grep -v "grep" --color=auto | grep -v "lua -e SERVER_CONFIG" --color=auto
    echo ""
}

# set env

if [ "$1" != "quiet" ]; then
    echo -e "\033[31mROOT_DIR\033[0m=$ROOT_DIR"
    echo ""
fi

cd $ROOT_DIR

LUA_BIN=$ROOT_DIR/bin/openresty/luajit/bin/lua
NGINX_DIR=$ROOT_DIR/bin/openresty/nginx
REDIS_DIR=$ROOT_DIR/bin/redis

TMP_DIR=$ROOT_DIR/tmp

CONF_DIR=$ROOT_DIR/conf

CONF_PATH=$CONF_DIR/config.lua
NGINX_CONF_PATH=$CONF_DIR/nginx.conf
REDIS_CONF_PATH=$CONF_DIR/redis.conf

VAR_CONF_PATH=$TMP_DIR/config.lua
VAR_NGINX_CONF_PATH=$TMP_DIR/nginx.conf
VAR_REDIS_CONF_PATH=$TMP_DIR/redis.conf
VAR_BEANS_LOG_PATH=$TMP_DIR/beanstalkd.log

VERSION=$(getVersion)
OS_TYPE=$(getOsType)
if [ $OS_TYPE == "MACOS" ]; then
    SED_BIN='sed -i --'
else
    SED_BIN='sed -i'
fi
