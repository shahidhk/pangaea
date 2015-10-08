#!/bin/bash

CACHE_FILE=/pangaea/.tmp/docker_cache.tar.gz
tar -xzf $CACHE_FILE -C /var/lib
echo 'PAN CACHE RESTORE: docker'
