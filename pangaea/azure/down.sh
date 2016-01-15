#!/bin/bash

set -e

SCRIPT_DIR=`dirname $0`
ROOT_DIR=$SCRIPT_DIR/../..

source $ROOT_DIR/.pangaea

azure group delete -q --name "$AZURE_NAME"
