# Workflow

Pangaea is a collection of scripts designed primarily to make working on the Kubernetes platform more efficient. Here's an opinionated guide on how to develop a containerized application on your local machine, and then deploy it to GCE. We use an nginx container with a customized index page as an example.

## Step 1: Setup

- Clone this repository, this will serve as the root project folder for your application
- git remote remove origin
- Create a new repository to host your application
- git remote add origin git://path/to/your/git/repo
- git checkout master
- git push -u origin master
- You've now set up a new git repository for your application

To upgrade Pangaea

- git remote add pangaea git://path/to/this/git/repo
- git fetch pangaea
- git merge pangaea/master

## Step 2: Directory Structure and Basic Service Setup

- Assuming you're in the project root
- Let's create a folder to hold our application called app
- mkdir app
- We create a folder for each service we run
- mkdir -p app/nginx
- Let's create our customized index.html file
- mkdir app/nginx/html
- echo "THIS IS OUR CUSTOMIZED INDEX.HTML CONTENT" > app/nginx/html/index.html
- Create a Dockerfile to create a customized nginx container
- vim app/nginx/Dockerfile  
```
FROM nginx
ADD html /var/html
```
- Create a Kubernetes object spec for our nginx replication controller and service
- vim app/nginx/nginx.yml  
```yaml
---
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
        - image: nginx-customized
          name: nginx
---
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
    - nodePort: 30080 <!!!!! WHAT THIS DOCS>
  selector:
    app: nginx
```

## Step 3: Run the nginx

First bring up our Kubernetes node

- Set the following in the .pangaea file
    - PROVIDER=vagrant
    - KUBE_LOGGING and KUBE_MONITORING to either true or false
    - KUBE_GCR_CREDENTIALS=true if you intent to use GCR as your private Docker repository
- pangaea/vagrant/kubesetup.sh
- If you're using GCR, follow the section 'Enable your Kubernetes node to download images from a private Google Cloud Registry' on README.md <!!!! LINK>

Let's now run our nginx container on Kubernetes

- docker build
- docker push nginx-customized
- kubectl create -f app/nginx/nginx.yml
- Wait for a while for the image to be downloaded and run
- We know the service is ready when we can see both the service IP and an endpoint IP address that corresponds to the running pod
- watch -n1 kubectl describe svc nginx
- curl 172.17.6.101:30080
- You should see the contents of the index file we created above

## Step 4: Local Development

The primary objective in local development is to shorten the feedback loop between making a change and seeing it work.

We also want to make the Kubernetes setup process as smooth as possible so we can simply use it as a basic building block. We want to cache downloaded files so that we save time on future re-creates.

Set up Kubernetes

- pangaea/vagrant/kubesetup.sh
- This script starts a CoreOS VM on Vagrant, sets up Kubernetes, then uses Virtualbox's snapshotting mechanism to save state
- Running this script at any point of time will blow away all changes to the VM and reset it to this snapshot

Making changes in development

- In production, we expect the image to be fully self contained and include the index.html file with our content
- In development, we shadow the files we're going to modify by using folder mounts
- By default, on Vagrant, we mount the project root at /pangaea inside the CoreOS VM
- We want to modify our Kubernetes spec file to mount the html folder, but only in development, so we use templating
- Install kubetemplate, a command line tool for Jinja templating with Kubernetes specific helpers
- pip3 install kubetemplate
- #
