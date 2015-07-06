#!/bin/bash
#
# Usage: bash downloadSparkJobResult.sh spark-master-ip

MASTER_HOSTNAME=$1

if [ -z "$1" ]; then
    echo "Please provide the Spark master's IP."
    exit 1
fi

# print commands and outputs after here
set -ex
# 

sshpass -p savi ssh -o 'StrictHostKeyChecking no' ubuntu@$MASTER_HOSTNAME "rm -rf /home/ubuntu/output.txt && sudo hadoop fs -get hdfs://$MASTER_HOSTNAME/user/ubuntu/files/output/part-00000 /home/ubuntu/output.txt && cat /home/ubuntu/output.txt"

