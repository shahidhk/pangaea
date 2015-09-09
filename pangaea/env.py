# pangaea tool
# env [-t TOOL]

import argh
import glob
import os

from pangaea import utils
from pangaea import compile

def env(
        tool : 'tool to print environment for' = 'ALL'
    ):

    gpath = None

    if tool == 'ALL':
        gpath = 'pan.*'
    else:
        gpath = 'pan.'+tool+'*'

    for f in glob.glob(os.path.join(utils.pangaea_path('pangaea/files/env/'), gpath)):
        with open(f) as fd:
            print(fd.read())

def command_hook(p):
    p = p.add_parser(
        'env',
         help='print environment variables for tooling',
         description="print environment variables for tooling\n"\
                     "supported tools: vagrant\n"\
                     "\"pangaea env [-t TOOL] | source /dev/stdin\" to set up environment variables"
    )
    argh.set_default_command(p, env)
