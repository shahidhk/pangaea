# Workflow

Pangaea is a collection of scripts designed primarily to make working on the Kubernetes platform more efficient. Here's an opinionated guide on how to develop a containerized application on your local machine with Vagrant, and then deploy it to GCE. We use an nginx container with a customized index page as an example.

See the [README](README.md) for a super brief summary instead.

- Step 1: Setup
- Step 2: Directory Structure and Creating a Customized nginx
- Step 3: Run the nginx Container
  - Kubernetes Object Specs
  - Start the App on Kubernetes
- Step 4: Local Development
  - Set Up Kubernetes
  - Making Changes in Development
  - Setting Up Port Forwarding
  - Using Virtualbox Snapshots Effectively
  - Upgrading Pangaea
- Step 5: Moving to Production
  - Create the Production Instance
  - Set Up the Application
  - Share the Setup With Your Team
  - Mounting GCE disks
  - Forward Docker and systemd Logs
  - Upgrading Pangaea
- Step 6: Helpful Scripts
- Further Study

## Step 1: Setup

- Clone this repository, this will serve as the root project folder for the application
- `git clone git@github.com:hasura/pangaea.git`
- `cd pangaea`
- Create a new repository to host the application
- `git remote set-url origin git://path/to/your/git/repo`
- `git push -u origin master`
- You've now set up a the git remote repository for the application

To upgrade Pangaea

- `git remote add pangaea git@github.com:hasura/pangaea.git`
- `git fetch pangaea`
- `git merge pangaea/master`
- See the Upgrading section under Vagrant and GCE below

## Step 2: Directory Structure and Creating a Customized nginx Container

- Assuming the current working directory is the project root
- Create a folder to hold the application called app
- `mkdir app`
- Create a folder for each service to be run
- `mkdir -p app/nginx`
- Create the customized index.html file
- `mkdir app/nginx/html`
- `echo "THIS IS OUR CUSTOMIZED INDEX.HTML CONTENT" > app/nginx/html/index.html`
- Create a Dockerfile to create a customized nginx container
- `vim app/nginx/Dockerfile`
```
FROM nginx
MAINTAINER Your Name Here
COPY html /usr/share/nginx/html
```
- `cd app/nginx`
- `docker build -t reponame/nginxcustomized .`
- `docker push reponame/nginxcustomized`
- `cd -`

## Step 3: Run the nginx Container

Run the Docker image built in the previous step on a Vagrant VM that runs Kubernetes.

### Kubernetes Object Specs

Create Kubernetes object specs for the nginx replication controller and service

- `vim app/nginx/nginx-rc.yml`
```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
  labels:
    app: nginx
    version: v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
        version: v1
    spec:
      containers:
        - image: reponame/nginxcustomized
          name: nginx
```
- `vim app/nginx/nginx-svc.yml`
```yaml
kind: Service
apiVersion: v1
metadata:
  name: nginx
  labels:
    app: nginx
    version: v1
spec:
  type: LoadBalancer
  ports:
    - port: 80
      nodePort: 30080
  selector:
    app: nginx
```

### Start the App on Kubernetes

Bring up a Kubernetes node

- Set the following in the .pangaea file
    - `PROVIDER=vagrant`
- `pangaea/vagrant/kubesetup.sh`

Let's now run the nginx container on Kubernetes

- `kubectl create -f app/nginx/nginx-rc.yml`
- `kubectl create -f app/nginx/nginx-svc.yml`
- Wait for a while for the image to be downloaded and run
- We know the service is ready when we can see both the service IP and an endpoint IP address that corresponds to the running pod (press ctrl-C to stop the watch command)
- `watch -n1 kubectl describe svc nginx`
- `curl 172.17.6.101:30080`
- You should see the contents of the index file created above

## Step 4: Local Development

The primary objective in local development is to shorten the feedback loop between making a change and seeing it work.

We also want to make the Kubernetes setup process as smooth as possible so we can simply use it as a basic building block. We want to cache downloaded files so that we save time on future setups.

### Set Up Kubernetes

- `pangaea/vagrant/kubesetup.sh`
- This script starts a CoreOS VM on Vagrant, sets up Kubernetes, then uses Virtualbox's snapshotting mechanism to save state
- Running this script at any future point of time will blow away all changes to the VM and reset it to this snapshot

### Making Changes in Development

- In production, we expect the image to be fully self contained and include the index.html file with our customized content
- In development, we shadow the files we're going to customize by using folder mounts (file mounts work alright till they're edited outside the container so we don't use them)
- By default, on Vagrant, we mount the project root at /pangaea inside the CoreOS VM using nfs
- We want to modify our Kubernetes spec file to mount the html folder, but only in development, so we use templating
- Install kubetemplate, a command line tool for Jinja templating with Kubernetes specific helpers
- `pip3 install kubetemplate`
- Create a .kubetemplate file with information about compilation targets and templatable variables
- `vim .kubetemplate`
```yaml
compiler:
  targets:
    - path: app/nginx/nginx-rc.yml.jinja

environment: development
```
- The .kubetemplate yaml is available in the `config` variable in Jinja
- Modify the nginx.yml file to use Jinja templating
- `mv app/nginx/nginx-rc.yml app/nginx/nginx-rc.yml.jinja`
- `vim app/nginx/nginx-rc.yml.jinja`
```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
  labels:
    app: nginx
    version: v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
        version: v1
    spec:
      containers:
        - image: reponame/nginxcustomized
          name: nginx
{% if config['environment'] == 'development' %}
          volumeMounts:
            - name: nginx-html
              mountPath: /usr/share/nginx/html
      volumes:
        - name: nginx-html
          hostPath:
            path: /pangaea/app/nginx/html
{% endif %}
```
- Run kubet to compile the Jinja template to app/nginx/nginx-rc.yml
- `kubet`
- Delete the nginx rc if you'd already created it
- `kubectl delete -f app/nginx/nginx-rc.yml`
- Recreate the nginx service
- `kubectl create -f app/nginx/nginx-rc.yml`
- Wait for the service to be set up
- `watch -n1 kubectl describe svc nginx`
- Let's get our content
- `curl 172.17.6.101:30080`
- Now, modify our custom content
- `echo 'HERE IS SOME MORE CONTENT FOR OUR INDEX.HTML FILE' >> app/nginx/html/index.html`
- Let's get our updated content
- `curl 172.17.6.101:30080`
- This time, you should see the additional line of content

### Setting Up Port Forwarding

- Edit the Vagrant configuration file and change the $forwarded_ports variable
- `vim pangaea/vagrant/config.rb`
```ruby
# ...
$forwarded_ports = { 443 => 1443, 30080 => 8080 }
# ...
```
- Reboot the Vagrant VM with the new configuration
- `vagrant reload`
- Get the content
- `curl localhost:8080`
- You should see the same output

### Using Virtualbox Snapshots Effectively

- Snapshotting is a feature you can use to save the entire VM disk state exactly as is
- Virtualbox makes snapshots in a tree structure, so we can use this like git
- For instance, use this to save the VM with all the images you just pulled, so you can revert to this snapshot instead of recreating the VM and waiting for all the images to be downloaded again
- To take a snapshot
- `vagrant snapshot take NameOfSnapshot`
- To list all snapshots
- `vagrant snapshot list`
- To revert to a snapshot
- `vagrant snapshot go NameOfSnapshot -r`
- The -r flag does a vagrant reload after reverting to the snapshot

### Upgrading Pangaea

- `vagrant reload`

## Step 5: Moving to Production

In production we want to run fully self contained containers so that we have an absolutely reproducable and scalable system.

- Build the modified files into the docker image, we reuse the same Dockerfile
- `cd app/nginx`
- `docker build -t reponame/nginxcustomized .`
- `docker push reponame/nginxcustomized`
- `cd -`


### Create the Production Instance

- Set settings in .pangaea
    - `PROVIDER=gce`
    - `GCE_INSTANCE_NAME` to the name of the compute instance we're going to create
- Let's create the Kubernetes node, and open up a firewall port to the apiserver
- `pangaea/gce/up.sh`
- kubectl has been configured to work with the GCE instance by the above script, let's use it to wait until the node is ready
- `watch -n1 kubectl get po --namespace=kube-system`
- Wait until all five pods are ready

### Set Up the Application

- Let's create our nginx rc and service
- `kubectl create -f app/nginx/nginx-rc.yml`
- `kubectl create -f app/nginx/nginx-svc.yml`
- Wait until the service has the associated endpoint IP address and also has an Ingress IP address that corresponds to the created GCE load balancer
- Let's see what nginx has to say
- `curl <LoadBalancerIP>`
- You should see the customized content we put in place

### Share the Setup With Your Team

- To communicate with the Kubernetes node, a workstation must have the corresponding certificates
- On the machine used to create the GCE instance, create a tar with the certs
- `tar -zcf /path/to/output/tar -C pangaea/pki/keys name-of-instance`
- Send the tar to a friend
- On another workstation
- `tar -xzf /path/to/the/tar -C pangaea/pki/keys`
- Set up .pangaea
    - `PROVIDER=gce`
    - `GCE_INSTANCE_NAME=name-of-instance`
- Configure kubectl
- `pangaea/bin/kubectl_setup`

### Mounting GCE disks

- First create the GCE disks manually, use pangaea/gce/disks_create.sh for reference
- `gcloud compute disks create disk-name --size 100GB`
- Edit .pangaea to include the disk names and mount points in variable GCE_DISK_MOUNTS
- `vim .pangaea`
```shell
# ...
GCE_DISK_MOUNTS=(
    disk-name /path/to/mount/disk
)
# ...
```
- If the instance already exists, attach the disks to the instance, otherwise they will be attached on create
- `gcloud compute instances attach-disk name-of-instance --disk disk-name`
- Create/upgrade the instance

### Forward Docker and systemd Logs

- set LOGROTATE_DOCKER to true in .pangaea
- [create](https://cloud.google.com/storage/docs/gsutil/commands/mb) a google cloud storage bucket
- use [logforward-gce](https://github.com/hasura/logforward-gce) to forward logs to the bucket

### Upgrading Pangaea

- Set GCE_INSTANCE_NAME in .pangaea
- Make sure you have the right credentials available
- `pangaea/gce/upgrade.sh`
- This will reboot the instance

## Step 5b: Move to Production on Azure

- `azure config mode arm`
- `azure login`
- Optionally, `azure account set <id>`
- `azure provider register Microsoft.Storage`
- `azure provider register Microsoft.Network`
- `azure provider register Microsoft.Compute`
TODO: TODO

## Step 6: Helpful Scripts

- Bash completion: source [this file](https://github.com/kubernetes/kubernetes/blob/master/contrib/completions/bash/kubectl)

## Further Study

- The idea is to crystallize all our knowledge, and all tasks we do more than once in scripts
- If you have any more ideas, share!
- Here are examples
- pangaea/gce/up.sh and pangaea/gce/down.sh
    - create and delete GCE instance
    - create and delete firewall rule to open port
    - copy files (aka scp) to google compute node
- pangaea/vagrant/Vagrantfile
    - verify environment before running Vagrantfile
    - trigger external scripts on provision using triggers
    - performant and functioning nfs mounts (use tcp instead of udp) without permissions issues (no_root_squash option)
- pangaea/pki/init-ssl
    - use openssl to generate pki
- pangaea/bin/kubectl_setup
    - configure kubectl with apiserver location and credentials
- pangaea/bin/vagrant
    - wrapper script that understands which project the current working directory corresponds to, then finds the vagrant binary it hides on the system, and runs it with the right Vagrantfile
    - this means you can add /path-to-project-root/pangaea/bin to your path and then use vagrant like normal in any pangaea project
- See README files in each directory in the pangaea directory for what that section is about
