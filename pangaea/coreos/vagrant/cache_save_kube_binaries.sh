#!/bin/bash

CACHE_FILE=/pangaea/.tmp/kubernetes.tar.gz
if [ -e $CACHE_FILE ]; then
  cp /tmp/kubernetes.tar.gz $CACHE_FILE
  echo 'PAN CACHE SAVE: kubernetes'
fi
