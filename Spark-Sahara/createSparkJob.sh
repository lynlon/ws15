#!/bin/bash

if [ -z "$1" ]; then
    echo "Please provide the binary job name."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Please provide the  job name."
    exit 1
fi

if [ -z "$OS_PASSWORD" ]; then
    echo "The environment variable OS_PASSWORD is not set."
    exit 1
fi

if [ -z "$OS_REGION_NAME" ]; then
    echo "The environment variable REGION_NAME is not set."
    exit 1
fi

if [ -z "$OS_USERNAME" ]; then
    echo "The environment variable USER_NAME is not set."
    exit 1
fi

if [ -z "$OS_TENANT_NAME" ]; then
    echo "The environment variable OS_TENANT_NAME is not set."
    exit 1
fi
export OS_AUTH_URL=http://iam.savitestbed.ca:5000/v2.0
binary_job_id=`sahara job-binary-list | grep $1 | awk '{print $2}'`
sahara job-template-create --name $2 --type Spark --main $binary_job_id
