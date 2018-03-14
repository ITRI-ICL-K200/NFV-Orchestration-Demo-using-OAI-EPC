#!/usr/bin/env python3

############################################################################
# Copyright 2016 RIFT.IO Inc                                               #
#                                                                          #
# Licensed under the Apache License, Version 2.0 (the "License");          #
# you may not use this file except in compliance with the License.         #
# You may obtain a copy of the License at                                  #
#                                                                          #
#     http://www.apache.org/licenses/LICENSE-2.0                           #
#                                                                          #
# Unless required by applicable law or agreed to in writing, software      #
# distributed under the License is distributed on an "AS IS" BASIS,        #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #
# See the License for the specific language governing permissions and      #
# limitations under the License.                                           #
############################################################################


import argparse
import logging
import paramiko
import os
import subprocess
import sys
import time

import yaml


def ssh(cmd, host, user, password):
    """ Run an arbitrary command over SSH. """

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    if password != 'none':
        client.connect(host, port=22, username=user, password=password)
    else:
        k = paramiko.RSAKey.from_private_key_file('/root/testInfo/oaikey.pem')
        client.connect(host, port=22, username=user, pkey =k)

    stdin, stdout, stderr = client.exec_command(cmd, get_pty=True)
    retcode = stdout.channel.recv_exit_status()
    client.close()

    return (
        retcode,
        stdout.read().decode('utf-8').strip(),
        stderr.read().decode('utf-8').strip()
    )

def main():#argv=sys.argv[1:]):
    try:
        parser = argparse.ArgumentParser()
        parser.add_argument("yaml_cfg_file", type=argparse.FileType('r'))
        parser.add_argument("-q", "--quiet", dest="verbose", action="store_false")
        args = parser.parse_args()
        yaml_str = args.yaml_cfg_file.read()
        yaml_cfg = yaml.load(yaml_str)
        add_GW = 'sudo route add default gw 10.101.136.254'
        clone = 'git clone https://github.com/ITRI-ICL-K200/NFV-Orchestration-Demo-using-OAI-EPC.git'
        s11_IP = ''
        hss_IP = ''

        for index, vnfr in yaml_cfg['vnfr'].items():
            def get_cp_ip(cp_name):
                for cp in vnfr['connection_point']:
                    if cp['name'].endswith(cp_name):
                        return cp['ip_address']
            mgmt_ip = vnfr['mgmt_ip_address']
            # add default
            ssh(add_GW,mgmt_ip, "ubuntu",'none')
            # git clone script
            ssh(clone,mgmt_ip, "ubuntu",'none')
            if 'HSS' in vnfr['name']:
                hss_IP = get_cp_ip('connection-point-2')
                # run HSS script
                run_script= 'sh ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/HSS_config.sh'
                ssh(run_script,mgmt_ip, "ubuntu",'none')
            if 'SPGW' in vnfr['name']:
                s11_IP = get_cp_ip('connection-point-2')
                # run spgw script
                tmp_script = 'sh ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/spgw_config.sh {public_IP} {S11_IP}'
                run_script  = tmp_script.format(public_IP=mgmt_ip, S11_IP=s11_IP)
                ssh(run_script,mgmt_ip, "ubuntu",'none')
                # run script

        for index, vnfr in yaml_cfg['vnfr'].items():
            def get_cp_ip(cp_name):
                for cp in vnfr['connection_point']:
                    if cp['name'].endswith(cp_name):
                        return cp['ip_address']
            if 'MME' in vnfr['name']:
                # run MME script
                mgmt_ip = vnfr['mgmt_ip_address']
                mme_s11_IP = get_cp_ip('connection-point-2')
                tmp_script = 'sh ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/MME_config.sh {public_IP} {S11_IP} {spgw_IP} {hss_IP}'
                run_script  = tmp_script.format(public_IP=mgmt_ip, S11_IP=mme_s11_IP, hss_IP=hss_IP, spgw_IP=s11_IP)
                ssh(run_script,mgmt_ip, "ubuntu",'none')
                # run script
    except Exception as e:
        logger.exception("Exception in {}: {}".format(__file__, e))

if __name__ == "__main__":
    main()
