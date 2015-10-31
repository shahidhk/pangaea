#!/bin/bash

# Replaces workstation vagrant keys mounted at /pangaea with the keys currently being used by the vagrant node

cp -r /opt/panwd/setup/pangaea/pki/keys/vagrant /pangaea/pangaea/pki/keys/
