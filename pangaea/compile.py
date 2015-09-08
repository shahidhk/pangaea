import os
import shutil
import glob
import argh

from pangaea import utils
from pangaea import template_helpers
from pangaea import props

__j = None # Jinja compiler

''' command line compile wrapper. parses command line arguments and config files. '''
def compile_c(input_t=None, output_t=None):
    if input_t is not None:
        return compile(input_t, output_t)
    else: # default to config file
        for t in props.get()['compiler']['targets']:
            to = t.get('to')
            to = to and utils.pangaea_path(to)
            compile(t['path'], to)

'''
    compile a glob-able path input_t
    output directory ouput_t when input_t is a file or directory, undefined behaviour for glob-able input_t
'''
def compile(
        input_t : 'input target path',
        output_t : 'output target path, defaults to same path' = None,
        ):

    input_t = os.path.abspath(input_t)
    output_t = output_t and os.path.abspath(output_t)

    for g in glob.glob(input_t):
        if os.path.isdir(g):
            for f in [
                    os.path.join(di, fi)
                    for (di, _, fis) in os.walk(g)
                    for fi in fis
                ]:
                outd = output_t \
                    and os.path.join(
                        output_t,
                        os.path.relpath(f, g)
                    ) \
                    or f
                outd = os.path.split(outd)[0]
                compile_file(f, outd)
        else:
            outd = output_t or os.path.split(input_t)[0]
            compile_file(g, outd)

''' compiles a single file '''
def compile_file(input_f, output_d):

    global __j
    if __j is None:
        context = props.get()

        context['helpers'] = template_helpers.helpers
        context['helpers']['compile'] = compile

        __j = JinjaCompiler('/', context)

    path, file_name = os.path.split(input_f)
    fname, ext = os.path.splitext(file_name)

    if ext == '.jinja':
        os.makedirs(output_d, exist_ok=True)
        output_f = os.path.join(output_d, fname)

        __j.compile(input_f, output_f)

        return output_f

class JinjaCompiler:
    def __init__(self, root_dir='/', config={}):
        from jinja2 import Environment, FileSystemLoader
        self.env = Environment(loader=FileSystemLoader(root_dir))
        self.env.globals['config'] = config

    def compile(self, in_file, out_file, config={}):
        with open(out_file, 'w') as f:
            f.write(self.env.get_template(in_file).render(config))

def command_hook(p):
    p = p.add_parser('compile', help='compile all templates')
    argh.set_default_command(p, compile_c)
