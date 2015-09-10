#!/usr/bin/env python3

# import pangaea
import importlib.machinery
import os

p = os.path.join(os.path.dirname(__file__), '../../__init__.py')
pangaea = importlib.machinery.SourceFileLoader('pangaea', p).load_module()

from pangaea import utils, props, helpers

# imports
import subprocess, json, time

# wait for kube apiserver
print("Waiting for Kubernetes to boot to initialize kubesystem")

while True:
    if helpers.kube_running():
        break
    else:
        time.sleep(1)

kctl = utils.pangaea_path('pangaea/files/stubs/kubectl.py')
ppath = utils.pangaea_path('pangaea/files/kubernetes')
for i in os.listdir(ppath):
    if i != 'docker-gcr-credentials' or props.get()['pangaea']['docker_gcr_credentials']:
        nodes = subprocess.call('{} create -f "{}" 2>/dev/null'.format(kctl, os.path.join(ppath, i)), shell=True)

print("Kubesystem initialized")
