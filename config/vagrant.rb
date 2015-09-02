# Size of the CoreOS cluster created by Vagrant
$num_instances=1

# Enable port forwarding of Docker TCP socket
# Set to the TCP port you want exposed on the *host* machine, default is 2375
# If 2375 is used, Vagrant will auto-increment (e.g. in the case of $num_instances > 1)
# You can then use the docker tool locally by setting the following env var:
#   export DOCKER_HOST='tcp://127.0.0.1:2375'
#$expose_docker_tcp=2375

# Enable NFS sharing of your home directory ($HOME) to CoreOS
# It will be mounted at the same path in the VM as on the host.
# Example: /Users/foobar -> /Users/foobar
#$share_home=false

# Customize VMs
#$vm_gui = false
#$vm_memory = 1024
#$vm_cpus = 1

# Share additional folders to the CoreOS VMs
# For example,
# $shared_folders = {'/path/on/host' => '/path/on/guest', '/home/foo/app' => '/app'}
# or, to map host folders to guest folders of the same name,
# $shared_folders = Hash[*['/home/foo/app1', '/home/foo/app2'].map{|d| [d, d]}.flatten]
#$shared_folders = {}

# Enable port forwarding from guest(s) to host machine, syntax is: { 80 => 8080 }, auto correction is enabled by default.
#$forwarded_ports = {}
$forwarded_ports = { 8080 => 8080 }

# Automatically replace the discovery token on 'vagrant up'
#$new_discovery_url="https://discovery.etcd.io/new?size=#{$num_instances}"
#cloud_config_path = File.join(File.dirname(__FILE__), "cloud_configs/self.yaml")
#if false && File.exists?(cloud_config_path) && ARGV[0].eql?('up')
#  require 'open-uri'
#  require 'yaml'
#
#  data = YAML.load(IO.readlines(cloud_config_path)[1..-1].join)
#
#  if data['coreos']['etcd2'].key? 'discovery'
#    token = open($new_discovery_url).read
#    data['coreos']['etcd2']['discovery'] = token
#  end
#
#  # Fix for YAML.load() converting reboot-strategy from 'off' to `false`
#  # if data['coreos']['update'].key? 'reboot-strategy'
#  #    if data['coreos']['update']['reboot-strategy'] == false
#  #       data['coreos']['update']['reboot-strategy'] = 'off'
#  #    end
#  # end
#
#  yaml = YAML.dump(data)
#  File.open(cloud_config_path, 'w') { |file| file.write("#cloud-config\n\n#{yaml}") }
#end
