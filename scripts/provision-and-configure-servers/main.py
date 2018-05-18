import time
import inspect
import sys
import os

import boto3
import pexpect
import requests

#
# parse ENV
#

def env_must_exist(env):
    if not str(os.environ[env]):
        raise Exception()
    return str(os.environ[env])

AWS_REGION_NAME =       env_must_exist('AWS_REGION_NAME')
AWS_ACCESS_KEY_ID =     env_must_exist('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = env_must_exist('AWS_SECRET_ACCESS_KEY')
AWS_HOSTED_ZONE_ID =    str(os.environ['AWS_HOSTED_ZONE_ID'])
AWS_DNS_NAME =          env_must_exist('AWS_DNS_NAME')
AWS_SSH_KEY_NAME =      env_must_exist('AWS_SSH_KEY_NAME')
AWS_SSH_KEY_PATH =      env_must_exist('AWS_SSH_KEY_PATH')
AWS_IMAGE_ID =          env_must_exist('AWS_IMAGE_ID')
AWS_SECURITY_GROUP_ID = env_must_exist('AWS_SECURITY_GROUP_ID')
RANCHER_USERNAME =      env_must_exist('RANCHER_USERNAME')
RANCHER_PASSWORD =      env_must_exist('RANCHER_PASSWORD')
NUMBER_OF_HOSTS =       env_must_exist('NUMBER_OF_HOSTS')


print('AWS_REGION_NAME=' + AWS_REGION_NAME)
print('AWS_ACCESS_KEY_ID=' + AWS_ACCESS_KEY_ID)
print('AWS_SECRET_ACCESS_KEY=' + AWS_SECRET_ACCESS_KEY)
print('AWS_HOSTED_ZONE_ID=' + AWS_HOSTED_ZONE_ID)
print('AWS_DNS_NAME=' + AWS_DNS_NAME)
print('AWS_SSH_KEY_NAME=' + AWS_SSH_KEY_NAME)
print('AWS_SSH_KEY_PATH=' + AWS_SSH_KEY_PATH)
print('AWS_IMAGE_ID=' + AWS_IMAGE_ID)
print('AWS_SECURITY_GROUP_ID=' + AWS_SECURITY_GROUP_ID)
print('RANCHER_USERNAME=' + RANCHER_USERNAME)
print('RANCHER_PASSWORD=' + RANCHER_PASSWORD)
print('NUMBER_OF_HOSTS=' + NUMBER_OF_HOSTS)


#
# helpers
#

def print_function_name():
    print('\n%s:' % inspect.stack()[1][3])

def create_instance(instanceType):
    print_function_name()

    ec2 = boto3.resource('ec2',
                         region_name=AWS_REGION_NAME,
                         aws_access_key_id=AWS_ACCESS_KEY_ID,
                         aws_secret_access_key=AWS_SECRET_ACCESS_KEY)

    instances = ec2.create_instances(ImageId=AWS_IMAGE_ID,
                                     BlockDeviceMappings=[{"DeviceName": "/dev/sda1", "Ebs": {"VolumeSize": 50}}],
                                     InstanceType=instanceType,
                                     KeyName=AWS_SSH_KEY_NAME,
                                     SecurityGroupIds=[AWS_SECURITY_GROUP_ID],
                                     MinCount=1,
                                     MaxCount=1)
    print(instances)
    return instances[0].id


def get_public_ip(instanceId):
    print_function_name()

    client = boto3.client('ec2', region_name=AWS_REGION_NAME,
                          aws_access_key_id=AWS_ACCESS_KEY_ID,
                          aws_secret_access_key=AWS_SECRET_ACCESS_KEY)

    state = {'PublicIpAddress': '', 'Counter': 10}
    while True:
        if state['Counter'] == 0:
            break

        response = client.describe_instances(InstanceIds=[instanceId])
        print(response)
        try:
            publicIpAddress = response['Reservations'][0]['Instances'][0]['PublicIpAddress']
        except KeyError:
            state['Counter'] = state['Counter'] - 1
            time.sleep(5)
            continue
        else:
            state['PublicIpAddress'] = publicIpAddress
            break

    if not state['PublicIpAddress']:
        raise Exception('Failed to get publicIpAddress!')

    return state['PublicIpAddress']


def add_server_name(instanceId, serverName):
    print_function_name()

    client = boto3.client('ec2', region_name=AWS_REGION_NAME,
                          aws_access_key_id=AWS_ACCESS_KEY_ID,
                          aws_secret_access_key=AWS_SECRET_ACCESS_KEY)
    response = client.create_tags(Resources=[instanceId], Tags=[{'Key': 'Name', 'Value': serverName}])
    print(response)


def update_dns_record(publicIpAddress, dnsName):
    print_function_name()

    client = boto3.client('route53', region_name=AWS_REGION_NAME,
                          aws_access_key_id=AWS_ACCESS_KEY_ID,
                          aws_secret_access_key=AWS_SECRET_ACCESS_KEY)

    changeBatch = {
        'Comment': 'Update record to reflect new IP address of home router',
        'Changes': [
            {
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': 'TODO',
                    'Type': 'A',
                    'TTL': 300,
                    'ResourceRecords': [
                        {
                            'Value': 'TODO',
                        }
                    ]
                }
            }
        ]
    }
    changeBatch['Changes'][0]['ResourceRecordSet']['ResourceRecords'][0]['Value'] = publicIpAddress
    changeBatch['Changes'][0]['ResourceRecordSet']['Name'] = dnsName
    response = client.change_resource_record_sets(HostedZoneId=AWS_HOSTED_ZONE_ID, ChangeBatch=changeBatch)
    print(response)

def wait_for_ssh_available(publicIpAddress, retries=120):
    print_function_name()
    print('connecting to:', publicIpAddress)

    while True:
        if retries == -1:
            raise Exception('failed to wait for ssh server to be available')
        try:
            cmd = 'ssh -i ' + AWS_SSH_KEY_PATH + ' rancher@' + publicIpAddress
            print('cmd:' + cmd)
            child = pexpect.spawn(cmd, timeout=5)
            i = child.expect([
                'Connection refused',
                'Are you sure you want to continue',
                'rancher@ip-',
                pexpect.EOF,
            ])
            if i == 0:
                print('server refused connection')
            if i == 1:
                child.sendline('yes')
                child.expect('rancher@ip-')
                child.sendline("exit")
                child.expect(pexpect.EOF)
                child.close()
                print('ssh service available - add to known hosts')
                break
            if i == 2:
                child.sendline("exit")
                child.expect(pexpect.EOF)
                child.close()
                print('ssh service available')
                break
            if i == 3:
                raise Exception('failed to connect to server, something unexpected happend')
        except Exception as e:
            print('server not available')
            print(e)
        retries = retries - 1
        time.sleep(5)

def wait_for_docker_is_alive(publicIpAddress):
    print_function_name()
    print('connecting to:' + publicIpAddress + ' and checking if docker is alive')

    try:
        child = pexpect.spawn('ssh -i ' + AWS_SSH_KEY_PATH + ' rancher@' + publicIpAddress, encoding='utf-8')
        child.logfile = sys.stdout
        child.expect('rancher@ip-')

        while True:
            child.sendline('docker info')
            i = child.expect(['Live Restore Enabled', 'Cannot connect to the Docker daemon at unix'])
            if i == 0:
                print("docker is running")
                break
            if i == 1:
                print("\ndocker not fully started yet, retrying")
                time.sleep(5)
                continue
        child.sendline("exit")
        child.expect(pexpect.EOF)
        child.close()
    except Exception as e:
        print('Exception: server not available')
        print(e)

def install_rancher_server(publicIpAddress):
    print_function_name()
    print('connecting to:' + publicIpAddress + ' and installing rancher')

    try:
        child = pexpect.spawn('ssh -i ' + AWS_SSH_KEY_PATH + ' rancher@' + publicIpAddress, encoding='utf-8')
        child.logfile = sys.stdout
        child.expect('rancher@ip-')

        child.sendline('docker run -d --restart=unless-stopped -p 8080:8080 rancher/server:v1.6.17')
        child.expect('Status: Downloaded newer image for rancher/server', timeout=300)
        child.expect('[0-9a-z]{64}\r')

        child.sendline("exit")
        child.expect(pexpect.EOF)
        child.close()
    except Exception as e:
        print('Exception: server not available')
        print(e)

def get_registration_token(publicIpAddress):
    print_function_name()

    print('create rancher account (1a1)')
    while True:
        try:
            response = requests.request('POST',
                                        url='http://' + publicIpAddress + ':8080/v2-beta/apikeys',
                                        headers={'Accept': 'application/json', 'Content-Type': 'application/json'},
                                        data={
                                            "type": "apikey",
                                            "accountId": "1a1",
                                            "name": "admin",
                                            "description": None,
                                            "created": None,
                                            "kind": None,
                                            "removed": None,
                                            "uuid": None,
                                        })
            print(response.json())
            break
        except requests.exceptions.ConnectionError:
            print('connection refused') # waiting for docker service to come up
            time.sleep(5)
            continue

    print('create registration token')
    response = requests.request('POST',
                     url='http://' + publicIpAddress + ':8080/v2-beta/projects/1a5/registrationTokens',
                     headers={'Accept': 'application/json', 'Content-Type': 'application/json'})
    print(response.json())
    type = response.json()['type']
    print('type:' + type)

    print('get registration token')
    while True:
        response = requests.request('GET',
                         url='http://' + publicIpAddress + ':8080/v2-beta/projects/1a5/registrationTokens',
                         headers={'Accept': 'application/json', 'Content-Type': 'application/json'})
        print(response.json())
        state = response.json()['data'][0]['state']
        print('state:' + state)

        if state == 'active':
            token = response.json()['data'][0]['token']
            print('token:' + token)
            break
        else:
            time.sleep(5)
            continue

    print('go visit ranger server at: http://' + publicIpAddress + ':8080/')

    return token

def generate_api_key(publicIpAddress):
    print_function_name()

    response = requests.request('POST',
                                url='http://' + publicIpAddress + ':8080/v1/projects/1a5/apikeys',
                                headers={'Accept': 'application/json', 'Content-Type': 'application/json'},
                                data='{"accountId": "a1", "publicValue": "publicKey", "secretValue": "secretKey"}')
    print(response.json())
    rancher_access_key = response.json()['publicValue']
    rancher_secret_key = response.json()['secretValue']
    print('rancher_access_key:'+rancher_access_key)
    print('rancher_secret_key:'+rancher_secret_key)
    return [rancher_access_key, rancher_secret_key]

def enable_rancher_access_control(publicIpAddress, username, password):
    print_function_name()

    response = requests.request('POST',
                                url='http://' + publicIpAddress + ':8080/v1/localauthconfig',
                                headers={'Accept': 'application/json', 'Content-Type': 'application/json'},
                                data='{"accessMode": "unrestricted", "enabled": true, "name": "admin", "username": "' + username + '", "password": "' + password + '"}')
    print(response.json())

def install_rancher_host(hostIp, serverIp, port, registrationToken):
    print_function_name()

    serverUrl = 'http://' + serverIp + ':' + port + '/v1/scripts/' + registrationToken
    cmd = 'docker run --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.2.10 ' + serverUrl

    print('connecting to:' + hostIp + ' and installing rancher host')
    try:
        child = pexpect.spawn('ssh -i ' + AWS_SSH_KEY_PATH + ' rancher@' + hostIp, encoding='utf-8')
        child.logfile = sys.stdout
        child.expect('rancher@ip-')

        child.sendline(cmd)
        child.expect('INFO: Launched Rancher Agent', timeout=300)
        child.expect('rancher@ip-')

        child.sendline("exit")
        child.expect(pexpect.EOF)
        child.close()
    except Exception as e:
        print('Exception: server not available')
        print(e)



#
# main
#

# build-server
instanceId = create_instance('t2.medium')
serverIp = get_public_ip(instanceId)
add_server_name(instanceId, 'build-server-x')
wait_for_ssh_available(serverIp)
wait_for_docker_is_alive(serverIp)
install_rancher_server(serverIp)
registrationToken = get_registration_token(serverIp)
rancher_access_key, rancher_secret_key = generate_api_key(serverIp)
enable_rancher_access_control(serverIp, RANCHER_USERNAME, RANCHER_PASSWORD)
install_rancher_host(serverIp, serverIp, "8080", registrationToken)
if AWS_HOSTED_ZONE_ID:
    update_dns_record(serverIp, AWS_DNS_NAME)                # 'hvt.zone.'
    update_dns_record(serverIp, '\\052.' + AWS_DNS_NAME)     # '\\052.hvt.zone.'


# hosts
def generate_hosts():
    for i in range(int(NUMBER_OF_HOSTS)):
        yield {'name': 'host'+str(i+1), 'instanceType': 't2.small'}

for host in generate_hosts():
    instanceId = create_instance(host['instanceType'])
    hostIp = get_public_ip(instanceId)
    add_server_name(instanceId, host['name'])
    wait_for_ssh_available(hostIp)
    wait_for_docker_is_alive(hostIp)
    install_rancher_host(hostIp, serverIp, "8080", registrationToken)


# results
print('\n')
print('export RANCHER_URL=http://' + serverIp + ':8080')
print('export RANCHER_ACCESS_KEY=' + rancher_access_key)
print('export RANCHER_SECRET_KEY=' + rancher_secret_key)
