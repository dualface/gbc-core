#!/bin/bash

ROOT_DIR=$(cd "$(dirname $0)" && pwd)
ROOT_DIR=$(dirname "$ROOT_DIR")
source "$ROOT_DIR/init.inc"

if [ $? -ne 0 ] ; then echo "Terminating..." >&2; exit 1; fi

multitail -csn -cS Apache -ke '^[0-9/]+ [0-9][0-9]:' -ke ' [0-9]+#[0-9]+: ' -ke ' functions\.lua:75: printlog\(\):' -ke ', client: .+$' "$ROOT_DIR/logs/error.log"

