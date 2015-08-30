# pangaea tool
# cluster {status, start, stop, reboot}

import argh
from pangaea.providers import vagrant

def status():
    vagrant.status()

def start():
    vagrant.start()

def stop():
    vagrant.stop()

def restart():
    vagrant.stop()
    vagrant.start()

def command_hook(p):
    p = p.add_parser('cluster', help='manage Kubernetes node')
    s = p.add_subparsers(title='Commands')

    q = s.add_parser('status')
    q.set_defaults(function=status)

    q = s.add_parser('start')
    q.set_defaults(function=start)

    q = s.add_parser('stop')
    q.set_defaults(function=stop)

    q = s.add_parser('restart')
    q.set_defaults(function=restart)
