#!/bin/bash
unset ERR
if [[ -n "$1" ]]; then
    GENI_USERNAME=$1
else
    ERR=1
fi

if [[ -z "$ERR" ]]; then
    sed -i 's/<GENI-Username>/'$GENI_USERNAME'/g' ./gee-tutorial-solution.yaml
    #[nodes]
    #    <geni_resource_name> ansible_ssh_port=22 ansible_ssh_user=<your_geni_username> ansible_ssh_key=~/.ssh/geni_key_portal
    #    <savi_resource_ip> ansible_ssh_port=22 ansible_ssh_user=ubuntu ansible_ssh_key=~/.ssh/geni_key_portal
else
    echo "Usage: ./setup-yaml.sh <GENI Username>"
fi

