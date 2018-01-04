#!/bin/bash
:<<tinywan
        [1]author:Tinywan
           github:https://github.com/Tinywan
        [2]log_format:
                [0] 语法格式：echo -e "\033[31m $msg \033[0m" >>log_file.log
                [1] error===>红色(31m)：错误日志信息
                [2] info===>绿色(32m)：命令成功执行、URL回调成功、打印正确数据信息
                [3] warn===>黄色(33m)：参数不存在、文件不存在、命令拼写错误
                [3] debug===>Blue色(34m)： debug
        [3]date:2017-04-04 10:23:10 [date '+%Y-%m-%d %H:%M:%S']
tinywan

#----------------------------基本信息-----------
PATH=/usr/local/bin:/usr/bin:/bin
ROOT_PATH=/home/www/record-data
FFMPEG_PATH=/usr/bin/ffmpeg
#------api config
API_SIGN="d25341478381063d1c76e81b3a52e0592a7c997f"
API_URL="https://www.tinywan.com/frontend/websocket_client/autoInstallConf"

YM=`date +%Y%m`
FLOG=/home/www/bin/logs/rtmp_record_${YM}.log
#设置日志级别 debug:0; info:1; warn:2; error:3
LOG_LEVEL=0
# 最小视频长度
MIN_DURATION=20
STREAM_NAME=$1
FULL_NAME=$2
FILE_NAME=$3
BASE_NAME=$4
DIR_NAME=$5

# -- record & oss
RECORD_RALLBACK_URL=$(curl -s "${API_URL}?sign=${API_SIGN}" | jq '.data.record_config.callback_url' | sed 's/\"//g')
OSS_UPLOAD_PATH=$(curl -s "${API_URL}?sign=${API_SIGN}" | jq '.data.oss_config.upload_path' | sed 's/\"//g')
# -- Redis
REDIS_HOST=$(curl -s "${API_URL}?sign=${API_SIGN}" | jq '.data.redis_config.host' | sed 's/\"//g')
REDIS_PORT=$(curl -s "${API_URL}?sign=${API_SIGN}" | jq '.data.redis_config.port' | sed 's/\"//g')
REDIS_AUTH=$(curl -s "${API_URL}?sign=${API_SIGN}" | jq '.data.redis_config.auth' | sed 's/\"//g')
REDIS_DB=$(curl -s "${API_URL}?sign=${API_SIGN}" | jq '.data.redis_config.db' | sed 's/\"//g')

echo -e  "\r\n \033[34m------------------------------------------------------Shell Script Start -------------------------------------------- \033[0m " >> $FLOG
function LOG(){
        local LOG_TYPE=$1
        local LOG_CONTENT=$2
        logformat="`date '+%Y-%m-%d %H:%M:%S'` \t[${LOG_TYPE}]\tFunction: ${FUNCNAME[@]}\t[line:`caller 0 | awk '{print$1}'`]\t [log_info: ${LOG_CONTENT}]"
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

function init_action(){
    # liveId
    LIVE_ID=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -a ${REDIS_AUTH} -n ${REDIS_DB} hget STREAM_GLOBAL:${STREAM_NAME} liveId)

    if [ -z "${STREAM_NAME}" ]; then
           LOG error "STREAM_NAME is null"
           exit 1
    fi

    LOG info "all params: $*"
    LOG debug "all param : STREAM_NAME = ${STREAM_NAME} FULL_NAME = ${FULL_NAME} FILE_NAME = ${FILE_NAME} BASE_NAME = ${BASE_NAME} DIR_NAME = ${DIR_NAME}"

    if [ -z "${FULL_NAME}" ]; then
            LOG error "FULL_NAME is null"
            exit 1
    fi

    if [ ! -s "${FULL_NAME}" ]; then
            LOG error "File not exists or zero size "
            # 文件为空文件删除掉该文件
            rm -f ${FULL_NAME}
            exit 1
    fi
    # 创建对应的本地存储目录
    VIDEO_PATH=$ROOT_PATH/$STREAM_NAME/video
    mkdir -p $VIDEO_PATH
}

function get_duration(){
    DURATION=$(${FFMPEG_PATH} -i ${FULL_NAME} 2>&1 | awk '/Duration/ {split($2,a,":");print a[1]*3600+a[2]*60+a[3]}')
    if [ $(echo "$DURATION < $MIN_DURATION"|bc) = 1 ]; then
            LOG error " duration too short, FULL_NAME=${FULL_NAME}, DURATION==${DURATION}"
            rm -f ${FULL_NAME}
            exit 1
    fi
}

# 自动截取封面图片
function ffmpeg_auto_cut_image(){
    FFMPEG_JPG=$(${FFMPEG_PATH} -y -ss 00:00:10 -i ${FULL_NAME} -vframes 1 ${VIDEO_PATH}/${BASE_NAME}.jpg && echo "success" || echo "fail")
    LOG info "Screenshot JPG: ${FFMPEG_JPG} "
}

# 转码成MP4
function ffmpeg_auto_encode_mp4(){
    FFMPEG_MP4=$(${FFMPEG_PATH} -y -i ${FULL_NAME} -vcodec copy -acodec copy ${VIDEO_PATH}/${BASE_NAME}.mp4 && echo "success" || echo "fail")
    LOG info "Transcoding MP4: ${FFMPEG_MP4} "

    FILE_SIZE=`stat -c "%s" ${VIDEO_PATH}/${BASE_NAME}.mp4`
    FILE_TIME=`stat -c "%Y" ${FULL_NAME}`
    LOG debug "FILE_NAME=${FILE_NAME}, DURATION=${DURATION}, FILESIZE=${FILE_SIZE},FILETIME=${FILE_TIME}"
}

# 上传至阿里云OSS
function upload_oss(){
    commandJPG=$(osscmd put $VIDEO_PATH/$BASE_NAME.jpg $OSS_UPLOAD_PATH$STREAM_NAME/video/$BASE_NAME.jpg && echo "success" || echo "fail")
    commandMP4=$(osscmd put $VIDEO_PATH/$BASE_NAME.mp4 $OSS_UPLOAD_PATH$STREAM_NAME/video/$BASE_NAME.mp4 && echo "success" || echo "fail")
    
    LOG debug " Oss Jpg upload ${commandJPG}"
    LOG debug "Oss Mp4 upload $commandMP4"
}

function ffmpeg_auto_slice_ts(){
    mkdir -p ${DIR_NAME}/${BASE_NAME}
    FFMPEG_RUN=$(${FFMPEG_PATH} -i ${FULL_NAME} -flags +global_header -f segment -segment_time 3 -segment_format mpegts -segment_list ${DIR_NAME}/${BASE_NAME}/index.m3u8 -c:a copy -c:v copy -bsf:v h264_mp4toannexb -map 0 ${DIR_NAME}/${BASE_NAME}/%5d.ts && echo "200" || echo "500")
    # $? = 0 success or fail
    if [ "${FFMPEG_RUN}" == "200" ]; then
            LOG info "ffmpeg slice success ${FFMPEG_RUN}"
    elif [ "${FFMPEG_RUN}" == "500" ]
    then
            LOG error "ffmpeg slice error ${FFMPEG_RUN}"
            exit 1
    else
            LOG error "ffmpeg Unknown error"
            exit 1

    fi
    LOG debug "[$(date '+%Y-%m-%d %H:%M:%S')] ffmpeg finished slice ${FFMPEG_RUN} "
}

#recorded done rallback
function recorded_rallback(){
    URL="${RECORD_RALLBACK_URL}?streamName=${STREAM_NAME}&baseName=${BASE_NAME}&duration=${DURATION}&fileSize=${FILE_SIZE}&fileTime=${FILE_TIME}"
    RESULT=$(curl "${URL}" 2>/dev/null)
    RES_STATUS=${RESULT:0:3}
    RES_RESULT=${RESULT:4}
    #RESULT 返回值必须为字符串
    if [ "${RES_STATUS}" == "200" ]; then
            LOG info "recorded rallBack OK [${RES_RESULT}]"
    elif [ "${RES_STATUS}" == "500" ]
    then
            LOG error "recorded rallBack Fail [${RES_RESULT}]"
            exit 1
    else
            LOG error "recorded rallBack Unknown error URL = "$URL
            exit 1
    fi
}

# clear flv file
function clear_file(){
    LOG info "-------clear file"
    cd ${DIR_NAME}
    find ./  -mindepth 1 -maxdepth 3 -type f  -mmin +10080   | xargs rm -rf
    cd $ROOT_PATH 
    find ./  -mindepth 1 -maxdepth 3 -type f  -mmin +4320   | xargs rm -rf
}

function main(){
    init_action
    get_duration
    ffmpeg_auto_cut_image
    ffmpeg_auto_encode_mp4
    upload_oss
    #ffmpeg_auto_slice_ts
    recorded_rallback
    clear_file
}

main


