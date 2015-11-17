#!/bin/bash

ROOT_DIR=$(cd "$(dirname $0)" && pwd)
ROOT_DIR=$(dirname "$ROOT_DIR")
source "$ROOT_DIR/bin/init.inc"

if [ $? -ne 0 ]; then echo "Terminating..." >&2; exit 1; fi

DEBUG=1
updateAllConfigs

read -r -d '' CODE << EOT

package.path = "$ROOT_DIR/src/?.lua;$ROOT_DIR/src/lib/?.lua;" .. package.path

LUA_BIN = "$LUA_BIN"
SERVER_CONFIG = dofile("$ROOT_DIR/tmp/config.lua")
SERVER_APP_KEYS = dofile("$ROOT_DIR/tmp/app_keys.lua")
DEBUG = _DBG_WARN
TESTS_APP_ROOT = "$ROOT_DIR/tests"

require("framework.init")
local Tests = dofile("$ROOT_DIR/tests/run_tests_inc.lua")
local tests = Tests:create()
tests:run("$*")

EOT

$LUA_BIN -e "$CODE"
