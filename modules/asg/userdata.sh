#!/bin/bash
pip3.11 install ansible hvac 2>&1 | tee -a /opt/userdata.log
ansible-pull -i localhost, -U https://github.com/sridevopsb80/roboshop-ansible main.yml -e env=${env} -e role_name=${role_name} -e vault_token=${vault_token} 2>&1 | tee -a /opt/userdata.log

#script to be run while instance is being launched
#hvac is needed for vault_token
#ansible-pull command referenced from roboshop_ansible wrapper script
# tee command reads from the standard input and writes to both standard output and one or more files at the same time. we are using it to store output and error (2>&1) logs to /opt/userdata.log as well. -a is used for append.
# https://linuxize.com/post/linux-tee-command/

#vault_token is defined in github organizations. https://github.com/organizations/sridevopsb80/settings/secrets/actions. refer learn_github_actions/vault.yml

#check /opt/userdata.log to check logs and to make sure executions are fine
