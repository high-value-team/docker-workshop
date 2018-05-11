# scripts to provision AWS

This script will setup a rancher environment on aws.

### perpare

copy ssh key to ssh-key-directory
```
cp ~/.ssh/aws-ssh-key.pem ssh-key-directory/id_rsa.pem
```

edit environment variables
```
cp environment.example enviroment.list
vi environment.list
```

```
# build docker image
docker build --tag docker-workshop .
```

```
# start container (detached)
docker run -d --env-file environment.list  --volume (pwd)/ssh-key-directory:/ssh-key-directory docker-workshop
6b78caba67c784047037e4d56e9f6159c3dc077f4ae36f09274f40cb25bd0f6d

# follow logs (give it some time to display some output)
docker logs -f 6b78caba67c784047037e4d56e9f6159c3dc077f4ae36f09274f40cb25bd0f6d
```


### source

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
