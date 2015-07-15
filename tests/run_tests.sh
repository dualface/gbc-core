#!/bin/bash

ROOT_DIR=$(cd "$(dirname $0)" && pwd)
ROOT_DIR=$(dirname "$ROOT_DIR")
source "$ROOT_DIR/init.inc"

if [ $? -ne 0 ] ; then echo "Terminating..." >&2; exit 1; fi

DEBUG=1
updateAllConfigs

read -r -d '' CODE << EOT

package.path = '$ROOT_DIR/src/?.lua;' .. package.path
require('framework.init')
dofile('$ROOT_DIR/tests/tests.lua')

EOT

$LUA_BIN -e "$CODE"
