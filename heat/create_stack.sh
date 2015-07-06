#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Error: Incorrect number of paramters!"
    echo "Usage: ./create_stack.sh <name> <key_name>"
    exit 0
fi

NAME=$1
KEY_NAME=$2
#Where DB is located
REGION1=$OS_REGION_NAME
#Where Web Server is located
REGION2=CORE

if [ "$REGION1" == "$REGION2" ]; then
    REGION2=EDGE-TR-1
fi

nova --os-region-name $REGION1 keypair-add --pub_key $HOME/.ssh/id_rsa.pub $KEY_NAME
nova --os-region-name $REGION2 keypair-add --pub_key $HOME/.ssh/id_rsa.pub $KEY_NAME

TEMP_KEY1=`nova --os-region-name $REGION1 keypair-list | grep $KEY_NAME | awk '{print $2}'`
TEMP_KEY2=`nova --os-region-name $REGION2 keypair-list | grep $KEY_NAME | awk '{print $2}'`

if [ "$TEMP_KEY1" != "$KEY_NAME" ]; then
   echo "key $KEYNAME doesnt exist on $REGION1"
   exit 0
fi

if [ "$TEMP_KEY2" != "$KEY_NAME" ]; then
   echo "key $KEYNAME doesnt exist on $REGION2"
   exit 0
fi

TEMP_KEY1=`nova --os-region-name $REGION1 keypair-list | grep $KEY_NAME | awk '{print $4}'`
TEMP_KEY2=`nova --os-region-name $REGION2 keypair-list | grep $KEY_NAME | awk '{print $4}'`

if [ "$TEMP_KEY1" != "$TEMP_KEY2" ]; then
   echo "$KEYNAME fingerprints are different on two regions"
   exit 0
fi

heat stack-create $NAME -f wordpress_multi_region.yaml -P="key_name=$KEY_NAME;region1=$REGION1;region2=$REGION2"

echo "Creating stack \"$1\" with key, \"$KEY_NAME\".
The DB will be located on $REGION1.
The web server will be located on $REGION2."
