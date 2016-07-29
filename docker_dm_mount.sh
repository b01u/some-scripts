#!/bin/bash
#author: b0lu
#mail: b0lu_xyz@163.com
set -e
function usage(){
    echo '-----------BY B0LU-------------'
    echo 'Usage: bash '$0' container_name'
}
if [ $# -ne 1 ];then
    usage
fi

CONTAINER_NAME=$1
DOCKER_PROCESS=`ps aux|grep -i '/usr/bin/docker'`
if [ `echo $DOCKER_PROCESS|grep graph|wc -l` -eq 1 ]; then
    DOCKER_PATH=`echo $DOCKER_PROCESS|python -c "import sys,re;print re.findall(r\"--graph='(.*)'\",sys.stdin.read().strip())[0]"`
else
    DOCKER_PATH='/var/lib/docker'
fi
echo $DOCKER_PATH
METADATA_PATH=$DOCKER_PATH"/devicemapper/metadata/"
echo $METADATA_PATH
CONTAINERID=`docker ps -a |grep $CONTAINER_NAME|awk '{print $1}'`
CONFIG_FILE=$METADATA_PATH`ls $METADATA_PATH|grep $CONTAINERID|grep -v init`
echo $CONFIG_FILE
DEVICE_ID=`cat $CONFIG_FILE|python -c "import sys,json;config_data = sys.stdin.read().strip();print json.loads(config_data)['device_id']"`
echo $DEVICE_ID

DM_NAME=`dmsetup ls|grep -v skip_block_zeroing|sed -n '1p'|awk '{print $1}'`
DM_CONFIG_OLD=`dmsetup table $DM_NAME`
DM_CONFIG=`echo ${DM_CONFIG_OLD% *}`" $DEVICE_ID"
echo $DM_CONFIG

MOUNT_DIR=`mktemp -d`
DM_CREATE_NAME=`echo ${MOUNT_DIR##*/}`
dmsetup create $DM_CREATE_NAME --table "$DM_CONFIG"
if [ ! -d $MOUNT_DIR ]; then
    mkdir -p $MOUNT_DIR
fi
mount /dev/mapper/$DM_CREATE_NAME $MOUNT_DIR
ls $MOUNT_DIR
echo "挂载目录: "$MOUNT_DIR
