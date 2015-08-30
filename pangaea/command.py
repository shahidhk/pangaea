# pangaea <do something>

import argh

import cluster

def command():
    p = argh.ArghParser(description='Pangaea command centre', epilog='TODO:documentation')
    s = p.add_subparsers(title='Pangaea commands')

    # add subparsers
    cluster.command_hook(s)

    p.dispatch()

if __name__ == '__main__':
    command()
