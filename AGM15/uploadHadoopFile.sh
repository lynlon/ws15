#!/bin/bash
#
# Usage: bash uploadHadoopFile.sh spark-master-ip

MASTER_HOSTNAME=$1

if [ -z "$1" ]; then
    echo "Please provide the Spark master's IP."
    exit 1
fi

# print commands and outputs after here
set -ex
# 

sshpass -p savi ssh -o 'StrictHostKeyChecking no' ubuntu@$MASTER_HOSTNAME "wget https://www.gnu.org/licenses/gpl.txt && hadoop fs -mkdir hdfs://$MASTER_HOSTNAME/user/ubuntu/files ; hadoop fs -put ~/gpl.txt hdfs://$MASTER_HOSTNAME/user/ubuntu/files"
