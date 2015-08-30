# pangaea tool
# cluster status | start | stop | reboot

import providers.vagrant

def status():
    providers.vagrant.status()

def start():
    providers.vagrant.start()

def stop():
    providers.vagrant.stop()

def restart():
    providers.vagrant.stop()
    providers.vagrant.start()

def command_hook(p):
    p = p.add_parser('cluster', help='manage Kubernetes node')
    s = p.add_subparsers()

    q = s.add_parser('status')
    q.set_defaults(function=status)

    q = s.add_parser('start')
    q.set_defaults(function=start)

    q = s.add_parser('stop')
    q.set_defaults(function=stop)

    q = s.add_parser('restart')
    q.set_defaults(function=restart)
