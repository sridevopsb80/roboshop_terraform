#!/bin/bash
pip3.11 install ansible hvac 2>&1 | tee -a /opt/userdata.log
ansible-pull -i localhost, \
    -U https://github.com/sridevopsb80/roboshop-ansible main.yml \
    -e env=${env} -e role_name=${role_name} \
    -e vault_token=${vault_token} 2>&1 | tee -a /opt/userdata.log

# script will be invoked when instance is launched
# refer ec2/main.tf aws_instance.main
# variable values are passed there
# hvac is python package that is needed for python communication with hashicopr vault 
# ansible-pull command referenced from roboshop_ansible wrapper script

# vault_token is defined in github organizations. 
# https://github.com/organizations/sridevopsb80/settings/secrets/actions. 
# refer learn_github_actions/vault.yml

# check /opt/userdata.log to check logs and to make sure executions are fine
