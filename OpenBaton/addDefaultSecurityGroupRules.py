#!/usr/bin/env python
import json
import argparse
import os
import requests
import getpass
from requests.auth import HTTPBasicAuth

'''
need to install python-requests
sudo apt-get install python-requests 
'''


def getToken():
    url='http://{}:35357/v2.0/tokens'.format(openstackIp) 
    headers={'Content-Type':'application/json'}
    inputData={'auth': {'passwordCredentials': {'username': '{}'.format(user), 'password': '{}'.format(userPasswd)},"tenantName": "admin"}}
    response = requests.post(url, headers=headers, data=json.dumps(inputData) )
    if not process_response(response, False) :
        exit(1)
    reply_info = json.loads(response.content)
    token_data=reply_info['access']['token']
    if len(token_data) == 0 :
        print ''
        print '!!! ERROR: Get token error : no data'
        print ''
        return None, None

    token=token_data['id']
    tenantId=token_data['tenant']['id']
    
    #print 'token={}, tenantId={}'.format(token, tenantId)
    
    return token, tenantId


def getSecurityGroupId(token, tenantId):
    url='http://{}:9696/v2.0/security-groups'.format(openstackIp) 
    headers={'Content-Type':'application/json', 'X-Auth-Token': '{}'.format(token), 'Accept' : 'application/json' }
    response = requests.get(url, headers=headers )
    if not process_response(response, False) :
        exit(1)
    groups_data = json.loads(response.content)['security_groups']

    if len(groups_data) == 0 :
        print ''
        print '!!! ERROR: Get token error : no data'
        print ''
        return None

    securityGroupId=None
    for group in groups_data : 
        if group['name'] == 'default' and group['tenant_id'] == tenantId :
            securityGroupId=group['id']

    return securityGroupId


def addSecurityGroupRules(token, securityGroupId):
    url='http://{}:9696/v2.0/security-group-rules'.format(openstackIp) 
    headers={'Content-Type':'application/json', 'X-Auth-Token': '{}'.format(token), 'Accept' : 'application/json' }
    #add allow-all-tcp rule
    alltcpInputData={'security_group_rule': {'direction': 'ingress', 'port_range_min': 1, 'ethertype': 'IPv4', 'port_range_max': 65535, 'protocol': 'tcp', 'remote_ip_prefix': '0.0.0.0/0', 'security_group_id': '{}'.format(securityGroupId) }}
    response = requests.post(url, headers=headers, data=json.dumps(alltcpInputData) )
    if not process_response(response, False) :
        exit(1)
    print 'Allow-all-tcp rule is added!'

    #add allow-all-udp rule
    alludpInputData={'security_group_rule': {'direction': 'ingress', 'port_range_min': 1, 'ethertype': 'IPv4', 'port_range_max': 65535, 'protocol': 'udp', 'remote_ip_prefix': '0.0.0.0/0', 'security_group_id': '{}'.format(securityGroupId) }}
    response = requests.post(url, headers=headers, data=json.dumps(alludpInputData) )
    if not process_response(response, False) :
        exit(1)
    print 'Allow-all-udp rule is added!'

    #add allow-all-icmp rule
    allicmpInputData={'security_group_rule': {'direction': 'ingress', 'ethertype': 'IPv4', 'protocol': 'icmp', 'remote_ip_prefix': '0.0.0.0/0', 'security_group_id': '{}'.format(securityGroupId) }}
    response = requests.post(url, headers=headers, data=json.dumps(allicmpInputData) )
    if not process_response(response, False) :
        exit(1)
    print 'Allow-all-icmp rule is added!'


def poll_new_password(id):
    new_password = getpass.getpass(prompt='Enter new password for {}: '.format(id))
    new_password_repeated = getpass.getpass(prompt="Re-enter password: ")
    if new_password != new_password_repeated:
        print "Passwords did not match;  cancelling the add_user request"
        sys.exit(1)
    return new_password


def process_response( r, isPrn ):
    ''' Generic method to print result of a REST call '''
    print ''
    sc = r.status_code
    ret=False
    if sc >= 200 and sc < 300:
        if isPrn :
            print "command succeeded!"
            try:
                res = r.json()
                if res is not None:
                    print '\nInfo:\n', json.dumps(res, indent=4, sort_keys=True)
            except(ValueError):
                pass
        ret=True
    elif sc == 401:
        print "Incorrect Credentials Provided"
    elif sc == 404:
        print "Data NOT Found or RESTconf is either not installed or not initialized yet"
    elif sc >= 500 and sc < 600:
        print "Internal Server Error Ocurred"
    else:
        print "Unknown error; HTTP status code: {}".format(sc)
    return ret



if __name__ == '__main__':

    # main program arguments
    ### common arguemnts ###
    parser = argparse.ArgumentParser(description='add securit group rules to "default" group for "admin" tenant')  
    parser.add_argument('--user',help='username for login account', nargs=1) 
    parser.add_argument('--pwd',help='passwd for user to login', nargs=1)
    parser.add_argument('--openstack',help='the IP address of the openstack', nargs=1)
    parser.add_argument('--verbose',help='print detail infomation', action='store_true')

    args = parser.parse_args()


    if args.user is not None : 
    	user = args.user[0]
    else :
        print ''
        print '!!! ERROR: username is not specified!!'
        print ''
        parser.print_help()
        exit(1)

    if args.pwd is not None :
        userPasswd = args.pwd[0]
    else :
        userPasswd = getpass.getpass(prompt='Enter password for \" {} \": '.format(user))

    if args.openstack is not None :
        openstackIp = args.openstack[0]
    else :
        print ''
        print '!!! ERROR: openstack IP is not specified!!'
        print ''
        parser.print_help()
        exit(1)

    if len(userPasswd) == 0 or len(user) == 0 or len(openstackIp) == 0 :
        print ''
        print '!!! ERROR: input arguments error!!'
        print ''
        parser.print_help()
        exit(1)

    prnDetail = False
    if args.verbose :
        prnDetail = True

    if prnDetail :
        print 'user={} password={} openstack_ip={}'.format(user,userPasswd,openstackIp)

    token,tenantId=getToken()

    if prnDetail :
        print 'token={}, tenantId={}'.format(token, tenantId)

    if token == None or tenantId == None :
        exit(2)

    securityGroupId=getSecurityGroupId(token, tenantId)
    if securityGroupId == None :
        print ''
        print '!!! ERROR: get Security Group Id for name=default, tenant=admin  FAILURE!!'
        print ''
        exit(1)

    if prnDetail :
        print 'security group id for default in tenant=admin : {}'.format(securityGroupId)

    addSecurityGroupRules(token, securityGroupId)
