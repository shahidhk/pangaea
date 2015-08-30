import vagrant
import os

from utils import pangaea_path

vagrant_path = pangaea_path('pangaea/files/vagrant')

os_env = os.environ.copy()
os_env['VAGRANT_CWD'] = vagrant_path

v = vagrant.Vagrant(env=os_env, quiet_stdout=False, quiet_stderr=False)

def status():
    print(v.status())

def start():
    v.up()

def stop():
    v.halt()

def env():
    return "# Vagrant working directory\n"\
           "export VAGRANT_CWD={}".format(vagrant_path)
