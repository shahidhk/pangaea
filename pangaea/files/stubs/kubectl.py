#!/usr/bin/env python3

# import pangaea
import importlib.machinery
import os

p = os.path.join(os.path.dirname(__file__), '../../__init__.py')
pangaea = importlib.machinery.SourceFileLoader('pangaea', p).load_module()

from pangaea import helpers, props

# imports
import sys, subprocess

# kubectl wrapper

flags = ''

if props.get()['provider'] == 'gce':
    try:
        ip = helpers.kube_apiserver_ip()
    except helpers.KubeIPNotFound as e:
        sys.exit(str(e))
    flags = flags + ' -s ' + ip

cmd = 'kubectl{} {}'.format(flags, ' '.join(sys.argv[1:]))
subprocess.call(cmd, shell=True)
