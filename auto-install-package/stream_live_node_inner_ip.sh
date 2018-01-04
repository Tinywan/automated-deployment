#!/bin/bash
:<<tinywan
[1] Author：Tinywan
    Github: https://github.com/Tinywan
[2] function: 节点服务器脚本自动把自己的内网和外网IP地址写入到Redis数据中去
tinywan

PATH=/usr/local/bin:/usr/bin:/bin
FLOG=/home/www/bin/logs/stream_live_node_inner_ip.log
TIME=`date '+%Y-%m-%d %H:%M:%S'`

# api config
SIGN="d25341478381063d1c76e81b3a52e0592a7c997f"
API_URL="https://www.tinywan.com/frontend/websocket_client/autoInstallConf"

# redis config
REDIS_HOST=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.redis_config.host' | sed 's/\"//g')
REDIS_PORT=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.redis_config.port' | sed 's/\"//g')
REDIS_AUTH=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.redis_config.auth' | sed 's/\"//g')
REDIS_DB=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.redis_config.db' | sed 's/\"//g')

STREAM_ID=$1

if [ -z "$STREAM_ID" ]; then
        echo "[ERROR][$TIME] device_id is null" >> $FLOG
        exit 1
fi

INNER_IP=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:" | sed -n '1p;1q')
OUTER_IP=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:" | sed -n '2p;2q')

STREAM_URL=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_AUTH -n $REDIS_DB hMset 'StreamLiveNodeInnerIp:'$STREAM_ID outerip ${OUTER_IP} steamName ${STREAM_ID} livenode "http://${OUTER_IP}")
exit 1


