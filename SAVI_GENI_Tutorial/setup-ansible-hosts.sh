#!/bin/bash
unset ERR
if [[ -n "$1" ]]; then
    GENI_USERNAME=$1
else
    ERR=1
fi

if [[ -n "$2" ]]; then
    GENI_SLICE=$2
else
    ERR=1
fi


if [[ -z "$ERR" ]]; then
    touch ansible-hosts
    echo "[nodes]" > ansible-hosts

    TEST=`./tutorial.sh listinstance geni $GENI_SLICE`

    GENI_HOSTNAME=`echo "$TEST" | grep hostname | cut -d "\"" -f 4`
    GENI_PORT=`echo "$TEST" | grep hostname | cut -d "\"" -f 6`

    echo "$GENI_HOSTNAME ansible_ssh_port=$GENI_PORT ansible_ssh_user=$GENI_USERNAME ansible_ssh_key=~/.ssh/geni_key_portal" >> ansible-hosts

    source savi_config
    source current_savi_config
    SAVI_IP=`./tutorial.sh listinstance savi $OS_REGION_NAME | grep ',' | cut -d ',' -f 2`

    echo "$SAVI_IP ansible_ssh_port=22 ansible_ssh_user=ubuntu ansible_ssh_key=~/.ssh/geni_key_portal" >> ansible-hosts

    #[nodes]
    #    <geni_resource_name> ansible_ssh_port=22 ansible_ssh_user=<your_geni_username> ansible_ssh_key=~/.ssh/geni_key_portal
    #    <savi_resource_ip> ansible_ssh_port=22 ansible_ssh_user=ubuntu ansible_ssh_key=~/.ssh/geni_key_portal
else
    echo "Usage: ./setup-ansible-hosts.sh <GENI Username> <GENI slice name>"
fi

