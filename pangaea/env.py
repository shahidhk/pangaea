# pangaea tool
# env [-t TOOL]

import argh
import importlib

from pangaea.utils import pangaea_path
from pangaea import tooling

supported_tools = ['vagrant']

for t in supported_tools:
    importlib.import_module('pangaea.tooling.{}'.format(t))

def env(
        tool : 'tool to print environment for' = 'ALL'
    ):
    if tool == 'ALL':
        print(
            "# Location of compiled files\n"\
            "export PAN=\"{}\"\n".format(pangaea_path('.pangaea'))
        )
        for t in supported_tools:
            print(getattr(getattr(tooling, t), 'print_env')())
    elif tool in supported_tools:
        print(getattr(getattr(tooling, tool), 'print_env')())
    else:
        print("Supported tools are: " + ' '.join(supported_tools))

def command_hook(p):
    p = p.add_parser(
        'env',
         help='print environment variables for tooling',
         description="print environment variables for tooling\n"\
                     "\"pangaea env [-t TOOL] | source /dev/stdin\" to set up environment variables"
    )
    argh.set_default_command(p, env)
