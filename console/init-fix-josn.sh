#!/bin/bash
API_SIGN=$1
API_URL="https://www.tinywan.com/frontend/websocket_client/autoInstallConf"
# 本地脚本路径
SCRIPT_PATH=/home/www/script/auto-install
# 远程脚本路径
REMOTE_PATH=/root

#exit 1
function log() {
    if [ $1 == "info" ]; then
        echo -e "\033[32;40m$2\033[0m"
    elif [ $1 == "error" ]; then
        echo -e "\033[31;40m$2\033[0m"
    elif [ $1 == "debug" ]; then
        echo -e "\033[34;40m$2\033[0m"
    fi
}

function update_sources_list(){
    #log debug "[`date '+%Y-%m-%d %H:%M:%S'`]  update sources.list ..."
    #cp -r /etc/apt/sources.list /etc/apt/sources.list.bak
    #cp -r $INSTALL_PACKAGE_PATH/auto-install-package/sources.list /etc/apt/sources.list
    apt-get update
    # 强制安装 jq
    apt-get install jq --force-yes -y
}

#update_sources_list

# 服务器组,密码最好设置为一样的  
SERVER_VAR=$(curl -s "${API_URL}?sign=${API_SIGN}" | jq '.data.server_config.ip_group' | sed 's/\"//g')
PWDS_VAR=$(curl -s "${API_URL}?sign=${API_SIGN}" | jq '.data.server_config.pwd_group' | sed 's/\"//g')

OLD_IFS="$IFS"
IFS=","
SERVERS=($SERVER_VAR)
PASSWORDS=($PWDS_VAR)
IFS="$OLD_IFS"

log info "[`date '+%Y-%m-%d %H:%M:%S'`] Api Sign= ${API_SIGN}"

function check_sign(){
    log info "[`date '+%Y-%m-%d %H:%M:%S'`] Starting Check Api Sign ..."
    API_CODE=$(curl -s "${API_URL}?sign=${API_SIGN}" | jq '.code' | sed 's/\"//g')
    if [ "${API_CODE}" == "200" ]; then
            log  info "[`date '+%Y-%m-%d %H:%M:%S'`] Congratulations Api call success"
    elif [ "${API_CODE}" == "500" ]
    then
            log error "[`date '+%Y-%m-%d %H:%M:%S'`] Api access failed"
            exit 1
    else
            log error "[`date '+%Y-%m-%d %H:%M:%S'`]  Unknown error"
            exit 1
    fi
}

#for i in ${SERVERS[@]}
#do
#  echo "SERVERS == "$i
#done

#for j in ${PASSWORDS[@]}
#do
#  echo "PASSWORDS == "$j
#done

#SERVER_NUMS=(0 1)
init(){
   for(( count=0;count<=${#SERVERS[@]}-1;count+=1 ))
   do
   	SERVER_NUMS[$count]=$count
   done
}
# 免密码登陆
auto_by_ssh_copy_id() {
	expect -c "
	set timeout -1
	spawn ssh-copy-id -i /home/www/.ssh/id_rsa.pub root@$1
	expect {
	    *(yes/no)* {send -- yes\r;exp_continue;}
            *assword:* {send -- $2\r;exp_continue;}
            eof        {exit 0;}
        }"
}

# 遍历服务器
ssh_copy_id_all() {
    for index in "${SERVER_NUMS[@]}"
    do
       auto_by_ssh_copy_id ${SERVERS[$index]} ${PASSWORDS[$index]}
       #echo ${SERVERS[$index]} ${PASSWORDS[$index]}
       sleep 1	
    done
}

# ssh 自动登录
ssh_login(){
    for SERVER in "${SERVERS[@]}"
    do
	# cp simlpe file
        # scp $SCRIPT_PATH/install.sh root@$SERVER:$REMOTE_PATH
        # cp dir
	scp -r $SCRIPT_PATH/auto-install-package root@$SERVER:$REMOTE_PATH
        ssh root@$SERVER $REMOTE_PATH/auto-install-package/install.sh $SERVER_VAR $SERVER $API_SIGN 
    done
}

# 入口
main(){
    check_sign
    init
    ssh_copy_id_all
    ssh_login
}

main
