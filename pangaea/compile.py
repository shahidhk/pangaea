import os
import shutil
import glob
import argh

from pangaea import utils
from pangaea import template_helpers
from pangaea import props

def compile(target=None):

    context = props.get()

    context['helpers'] = template_helpers.helpers
    context['helpers']['compile'] = compile

    compilation_targets = target and [target] or context['pangaea']['compiler']['targets']
    if '.pangaea' in compilation_targets:
        compilation_targets.remove('.pangaea')

    root_dir = utils.pangaea_path('.')
    os.makedirs(os.path.join(root_dir, '.pangaea'), exist_ok=True)

    old_root_dir = os.getcwd()
    os.chdir(root_dir)

    for tar in [
            g
            for t in compilation_targets
            for g in glob.glob(t)
        ]:

        if os.path.isdir(tar):
            for f in [
                os.path.join(di, fi)
                for (di, _, fis) in os.walk(tar)
                for fi in fis
                ]:
                compile_file(root_dir, f, context)
        else:
            compile_file(root_dir, f, context)

    os.chdir(old_root_dir)

    if target:
        return os.path.join(root_dir, '.pangaea', target)

def compile_file(root_dir, f, context):
    j = JinjaCompiler(root_dir, context)

    path, fil = os.path.split(f)
    fname, ext = os.path.splitext(fil)

    out_file = os.path.join('.pangaea', path, fname)
    os.makedirs(os.path.join('.pangaea', path), exist_ok=True)

    if ext == '.jinja':
        j.compile(f, out_file)
    elif context['pangaea']['compiler']['default_copy']:
        shutil.copyfile(f, os.path.join('.pangaea', f))

class JinjaCompiler:
    def __init__(self, root_dir, config={}):
        from jinja2 import Environment, FileSystemLoader
        self.env = Environment(loader=FileSystemLoader('.'))
        self.env.globals['config'] = config

    def compile(self, in_file, out_file, config={}):
        with open(out_file, 'w') as f:
            f.write(self.env.get_template(in_file).render(config))

def command_hook(p):
    p = p.add_parser('compile', help='compile all templates')
    argh.set_default_command(p, compile)
