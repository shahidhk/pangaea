from utils import pangaea_path
import props
import os
import shutil
import glob
import pdb

def compile():
    # all .jinja files are compiled, all other files are copied
    compilation_targets = [
        'pangaea',
        'app/*/kubefiles'
    ]
    if '.pangaea' in compilation_targets:
        compilation_targets.remove('.pangaea')

    join = os.path.join

    root_dir = pangaea_path('.')
    os.makedirs(join(root_dir, '.pangaea'), exist_ok=True)

    old_root_dir = os.getcwd()
    os.chdir(root_dir)

    j = JinjaCompiler(root_dir, props.get())

    for f in [
            join(di, fi)
            for t in compilation_targets
            for d in glob.glob(t)
            for (di, _, fis) in os.walk(d)
            for fi in fis
        ]:
        
        path, fil = os.path.split(f)
        fname, ext = os.path.splitext(fil)

        out_file = join('.pangaea', path, fname)
        os.makedirs(join('.pangaea', path), exist_ok=True)

        if ext == '.jinja':
            j.compile(f, out_file)
        else:
            shutil.copyfile(f, join('.pangaea', f))

    os.chdir(old_root_dir)

class JinjaCompiler:
    def __init__(self, root_dir, config={}):
        from jinja2 import Environment, FileSystemLoader
        self.env = Environment(loader=FileSystemLoader('.'))
        self.env.globals['config'] = config
    def compile(self, in_file, out_file, config={}):
        with open(out_file, 'w') as f:
            f.write(self.env.get_template(in_file).render(config))

if __name__ == '__main__':
    compile()
