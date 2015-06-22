
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

function getNginxNumOfWorker()
{
    CODE="_C=loadfile('$VAR_CONF_PATH')(); print(_C.numOfWorkers)"
    $LUA_BIN -e "$CODE"
}

function getNginxPort()
{
    CODE="_C=loadfile('$VAR_CONF_PATH')(); print(_C.port)"
    $LUA_BIN -e "$CODE"
}

function getRedisSocket()
{
    CODE="_C=loadfile('$VAR_CONF_PATH')(); if _C.redis and _C.redis.socket then print(string.sub(_C.redis.socket, 6)) end"
    $LUA_BIN -e "$CODE"
}

function getRedisHost()
{
    CODE="_C=loadfile('$VAR_CONF_PATH')(); if _C.redis and _C.redis.host then print(_C.redis.host) end"
    $LUA_BIN -e "$CODE"
}

function getRedisPort()
{
    CODE="_C=loadfile('$VAR_CONF_PATH')(); if _C.redis and _C.redis.port then print(_C.redis.port) end"
    $LUA_BIN -e "$CODE"
}

function getBeanstalkdHost()
{
    CODE="_C=loadfile('$VAR_CONF_PATH')(); if _C.beanstalkd and _C.beanstalkd.host then print(_C.beanstalkd.host) end"
    $LUA_BIN -e "$CODE"
}

function getBeanstalkdPort()
{
    CODE="_C=loadfile('$VAR_CONF_PATH')(); if _C.beanstalkd and _C.beanstalkd.port then print(_C.beanstalkd.port) end"
    $LUA_BIN -e "$CODE"
}

function getBeanstalkdNumOfWorker()
{
    CODE="_C=loadfile('$VAR_CONF_PATH')(); if _C.beanstalkd and _C.beanstalkd.numOfWorkers then print(_C.beanstalkd.numOfWorkers) else print(1) end"
    $LUA_BIN -e "$CODE"
}

# --

function updateConfig()
{
    cp -f $CONF_PATH $VAR_CONF_PATH
    $SED_BIN "s#_GBC_CORE_ROOT_#$ROOT_DIR#g" $VAR_CONF_PATH
    if [ -f "$VAR_CONF_PATH--" ]; then
        rm -f "$VAR_CONF_PATH--"
    fi
}

function updateNginxConf()
{
    cp -f $NGINX_CONF_PATH $VAR_NGINX_CONF_PATH
    $SED_BIN "s#_GBC_CORE_ROOT_#$ROOT_DIR#g" $VAR_NGINX_CONF_PATH

    NGINX_PORT=$(getNginxPort $ROOT_DIR)
    $SED_BIN "s#listen [0-9]*#listen $NGINX_PORT#g" $VAR_NGINX_CONF_PATH

    NGINX_NUM_OF_WORKERS=$(getNginxNumOfWorker $ROOT_DIR)
    $SED_BIN "s#worker_processes [0-9]*#worker_processes $NGINX_NUM_OF_WORKERS#g" $VAR_NGINX_CONF_PATH

    if [ "$DEBUG" == "1" ] ; then
        $SED_BIN "s#DEBUG = _DBG_ERROR#DEBUG = _DBG_DEBUG#g" $VAR_NGINX_CONF_PATH
        $SED_BIN "s#error_log logs/error.log;#error_log logs/error.log debug;#g" $VAR_NGINX_CONF_PATH
        $SED_BIN "s#lua_code_cache on#lua_code_cache off#g" $VAR_NGINX_CONF_PATH
    else
        $SED_BIN "s#DEBUG = _DBG_DEBUG#DEBUG = _DBG_ERROR#g" $VAR_NGINX_CONF_PATH
        $SED_BIN "s#error_log logs/error.log debug;#error_log logs/error.log;#g" $VAR_NGINX_CONF_PATH
        $SED_BIN "s#lua_code_cache off#lua_code_cache on#g" $VAR_NGINX_CONF_PATH
    fi

    if [ -f "$VAR_NGINX_CONF_PATH--" ]; then
        rm -f "$VAR_NGINX_CONF_PATH--"
    fi
}

function updateRedisConf()
{
    cp -f $REDIS_CONF_PATH $VAR_REDIS_CONF_PATH
    $SED_BIN "s#_GBC_CORE_ROOT_#$ROOT_DIR#g" $VAR_REDIS_CONF_PATH
    if [ -f "$VAR_REDIS_CONF_PATH--" ]; then
        rm -f "$VAR_REDIS_CONF_PATH--"
    fi
}

function updateAllConfigs()
{
    updateConfig
    updateNginxConf
    updateRedisConf
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
        REDIS_ARGS=""
        REDIS_SOCKET=$(getRedisSocket)
        if [ "$REDIS_SOCKET" == "" ]; then
            REDIS_HOST=$(getRedisHost)
            if [ "$REDIS_HOST" != "" ]; then
                REDIS_ARGS="$REDIS_ARGS -h $REDIS_HOST"
            fi

            REDIS_PORT=$(getRedisPort)
            if [ "$REDIS_PORT" != "" ]; then
                REDIS_ARGS="$REDIS_ARGS -p $REDIS_PORT"
            fi
        else
            REDIS_ARGS="-s $REDIS_SOCKET"
        fi

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
        BEANS_ARGS="-F"
        BEANS_HOST=$(getBeanstalkdHost)
        if [ "$BEANS_HOST" != "" ]; then
            BEANS_ARGS="$BEANS_ARGS -l $BEANS_HOST"
        fi
        BEANS_PORT=$(getBeanstalkdPort)
        if [ "$BEANS_PORT" != "" ]; then
            BEANS_ARGS="$BEANS_ARGS -p $BEANS_PORT"
        fi
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
    ps -ef | grep -i "start_workers.*sh" | grep -v "grep" > /dev/null
    if [ $? -ne 0 ]; then
        I=0
        rm -f $ROOT_DIR/logs/jobworker.log
        BEANS_NUM_OF_WORKERS=$(getBeanstalkdNumOfWorker)
        while [ $I -lt $BEANS_NUM_OF_WORKERS ]; do
            $ROOT_DIR/bin/instrument/start_workers.sh >> $ROOT_DIR/logs/jobworker.log &
            I=$((I+1))
        done
        echo "Start Job Workers DONE"
    else
        echo "Job Workers is already started"
    fi
    echo ""
}

function stopJobWorkers()
{
    echo "[CMD] killall start_workers.sh"
    if [ $OS_TYPE == "MACOS" ]; then
        ps -ef | grep "start_workers" | awk '{print $2}' | xargs kill -9 > /dev/null 2> /dev/null
    else
        killall start_workers.sh > /dev/null 2> /dev/null
    fi
    echo "[CMD] killall $CURRDIR/bin/openresty/luajit/bin/lua"
    killall -KILL $CURRDIR/bin/openresty/luajit/bin/lua > /dev/null 2> /dev/null
    echo "Stop Job Workers DONE"
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
            echo -e "\n$VERSION in \033[32mRELEASE\033[0m mode"
        else
            echo -e "\n$VERSION in \033[31mDEBUG\033[0m mode"
        fi
    fi

    echo -e "\n\033[33m[Nginx] \033[0m"
    ps -ef | grep -i "nginx" | grep -v "grep" --color=auto

    echo -e "\n\033[33m[Redis] \033[0m"
    ps -ef | grep -i "redis" | grep -v "grep" --color=auto

    echo -e "\n\033[33m[Beanstalkd] \033[0m"
    ps -ef | grep -i "beanstalkd" | grep -v "grep" --color=auto

    echo -e "\n\033[33m[Monitor] \033[0m"
    ps -ef | grep -i "monitor\.sh" | grep -v "grep" --color=auto | grep -v "lua -e SERVER_CONFIG" --color=auto

    echo -e "\n\033[33m[Job Worker] \033[0m"
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
