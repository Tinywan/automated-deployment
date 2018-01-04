#!/bin/bash
:<<tinywan
[1] Author：Tinywan
    Github: https://github.com/Tinywan
[2] function: 推流服务器URL分发流到节点服务器脚本
tinywan

STREAM_ID=$1
stream=${STREAM_ID%\?*}
FLOG=/home/www/bin/push_to_node.log
# api config
SIGN="d25341478381063d1c76e81b3a52e0592a7c997f"
API_URL="https://www.tinywan.com/frontend/websocket_client/autoInstallConf"

# redis config
REDIS_HOST=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.redis_config.host' | sed 's/\"//g')
REDIS_PORT=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.redis_config.port' | sed 's/\"//g')
REDIS_AUTH=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.redis_config.auth' | sed 's/\"//g')
REDIS_DB=$(curl -s "${API_URL}?sign=${SIGN}" | jq '.data.redis_config.db' | sed 's/\"//g')

echo -e  "\r\n \033[34m--------------------------------------------PushStream Shell Script Start -------------------------------------------- \033[0m " >> $FLOG
function LOG(){
        local LOG_TYPE=$1
        local LOG_CONTENT=$2
        logformat="`date '+%Y-%m-%d %H:%M:%S'` \t[${log_type}]\tFunction: ${FUNCNAME[@]}\t[line:`caller 0 | awk '{print$1}'`]\t [log_info: ${LOG_CONTENT}]"
        {
        case $LOG_TYPE in
                debug)
                        [[ $LOG_LEVEL -le 0 ]] && echo -e "\033[34m${logformat}\033[0m" ;;
                info)
                        [[ $LOG_LEVEL -le 1 ]] && echo -e "\033[32m${logformat}\033[0m" ;;
                warn)
                        [[ $LOG_LEVEL -le 2 ]] && echo -e "\033[33m${logformat}\033[0m" ;;
                error)
                        [[ $LOG_LEVEL -le 3 ]] && echo -e "\033[31m${logformat}\033[0m" ;;
        esac
        } | tee -a $FLOG
}

LOG debug "[${TIME}]: STREAM_ID == ${STREAM_ID} stream_id==${stream}"

# 判断当前流参数是否为空
if [ -z "${stream}" ]; then
        LOG error "stream_id is null"
        exit 1
fi

LOG debug "[${TIME}]: stream_id==${stream}"
# 添加本机外网IP到Redis中去
$(redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_AUTH -n $REDIS_DB hset 'StreamDropUrl:'${stream} drop_url '120.26.206.180')

#ALL_NODE_IP=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_AUTH -n $REDIS_DB hget 'GlobalTracking:'${stream} node_ip)
ALL_NODE_IP="live.tinywan.com|118.178.56.70|120.26.93.84"
LOG debug "ALL_NODE_IP == "${ALL_NODE_IP}
function get_all_node_ip(){
    if [ -z "${ALL_NODE_IP}" ]; then
            LOG error "[ERROR]: ALL_NODE_IP is null"
            exit 1
    fi
    LOG info " [SUCCESS]: ALL_NODE_IP:$ALL_NODE_IP"
    #分割IP地址
    CUT_NODE_IP=${ALL_NODE_IP//|/ } #将得到的节点中的|替换为空格
    for IP_ELEMINT in $CUT_NODE_IP
    do
        LOG debug "分发的节点IP地址: >>>>> $IP_ELEMINT "
        ffmpeg_node $IP_ELEMINT
    done
}

function ffmpeg_node(){
    NODE_IP=$1
    /usr/bin/ffmpeg -r 25 -i rtmp://localhost/live/${stream} -c copy -f flv rtmp://$NODE_IP/live/${stream} &
}

on_die ()
{
    pkill -KILL -P $$
}

trap 'on_die' TERM
   get_all_node_ip
wait
