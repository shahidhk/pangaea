#!/bin/bash

CACHE_FILE=/pangaea/.tmp/docker_cache.tar.gz
if [ -e $CACHE_FILE ]; then
  tar -zcf $CACHE_FILE -C /var/lib docker
  echo 'PAN CACHE SAVE: docker'
fi
