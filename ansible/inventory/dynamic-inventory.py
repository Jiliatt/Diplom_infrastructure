#!/usr/bin/env python3
import json
import os
import sys

def main():
    tfstate_path = '/home/user/proj/terraf/diplom_v1/terraform.tfstate'

    try:
        with open(tfstate_path, 'r') as f:
            tfstate = json.load(f)
        outputs = tfstate['outputs']
        ips = {
            'k8s_master_ip': outputs['k8s_master_ip']['value'],
            'k8s_app_ip': outputs['k8s_app_ip']['value'],
            'srv_monitoring_ip': outputs['srv_monitoring_ip']['value']
        }
        #print(f"DEBUG: IPs loaded: {ips}", file=sys.stderr)
    except:
        sys.exit(1)

    # ✅ ПРАВИЛЬНАЯ СТРУКТУРА: хосты + IP в hostvars
    inventory = {
        'all': {
            'hosts': ['k8s-master', 'k8s-worker', 'jenkins-node'],
            'children': {
                'k8s_masters': {
                    'hosts': ['k8s-master']
                },
                'k8s_workers': {
                    'hosts': ['k8s-worker']
                },
                'jenkins_nodes': {
                    'hosts': ['jenkins-node']
                }
            }
        },
        '_meta': {
            'hostvars': {
                'k8s-master': {
                    'ansible_host': ips['k8s_master_ip'],
                    'ansible_user': 'ubuntu',
                    'ansible_ssh_private_key_file': '~/.ssh/id_ed25519'
                },
                'k8s-worker': {
                    'ansible_host': ips['k8s_app_ip'],
                    'ansible_user': 'ubuntu',
                    'ansible_ssh_private_key_file': '~/.ssh/id_ed25519'
                },
                'jenkins-node': {
                    'ansible_host': ips['srv_monitoring_ip'],
                    'ansible_user': 'ubuntu',
                    'ansible_ssh_private_key_file': '~/.ssh/id_ed25519'
                }
            }
        }
    }

    print(json.dumps(inventory))

if __name__ == '__main__':
    main()
