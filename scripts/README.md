# Setup HVT Environment on AWS

Description TODO


## scripts to provision AWS

This script will setup a rancher environment on aws.

```
cd provision-and-configure-servers

# configure provide credentials, secrets, passwords, usernames, ...
cp run.example run.sh
vi run.sh

# copy aws ssh-key
cp ~/.ssh/frankfurt-rancher.pem id_rsa.pem

# build and execute scripts
docker build --tag provision-and-configure-servers .
docker run -rm provision-and-configure-servers
```


## deploy rancher stacks

Description TODO

```
cd deploy-hvt-apps

# configure provide credentials, secrets, passwords, usernames, ...
cp run.example run.sh
vi run.sh

# build and execute scripts
docker build --tag deploy-hvt-apps .
docker run -rm deploy-hvt-apps
```


## configure drone ci

Description TODO

visit http://drone.hvt.zone/account/token to get DRONE_TOKEN

```
cd configure-drone-ci

# configure provide credentials, secrets, passwords, usernames, ...
cp run.example run.sh
vi run.sh

# build and execute scripts
docker build --tag configure-drone-ci .
docker run -rm configure-drone-ci
```



## Technologies

* Python (boto3, pexpect)
* AWS (aws CLI, EC2, Route53)
* Docker (RancherOS, Rancher 1.6, Rancher CLI)
* Drone (Drone CLI)

## source

project structure:
* https://www.kennethreitz.org/essays/repository-structure-and-python
* https://stackoverflow.com/a/1783482/5011904

python virtual environment:
* https://docs.python.org/3/tutorial/venv.html#creating-virtual-environments

python and aws:
* https://linuxacademy.com/howtoguides/posts/show/topic/14209-automating-aws-with-python-and-boto3

python libraries:
* https://boto3.readthedocs.io/en/latest/index.html
* https://pexpect.readthedocs.io/en/stable/

inspiration:
* https://github.com/jeff1evesque/machine-learning/blob/508f572357966d621026ff144731a29c6faed939/install_rancher
* https://gist.github.com/mathuin/ed0fa5666e4f063b94abb5b1a49d9919
* http://tleyden.github.io/blog/2016/02/15/setting-up-a-self-hosted-drone-dot-io-ci-server/

automate drone setup
* https://github.com/drone/drone/issues/2129

drone:
* http://docs.drone.io/cli-installation/

rancher:
* https://rancher.com/docs/rancher/v1.6/en/cli/commands/

