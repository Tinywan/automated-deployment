#!/bin/bash
echo "init start ..............................."
# 本地脚本路径
SCRIPT_PATH=/home/www/script/auto-install
# 远程脚本路径
REMOTE_PATH=/root
# 服务器组,密码最好设置为一样的
#SERVER_NUMS=(0 1)
SERVER_VAR=$1
PWDS_VAR=$2
OLD_IFS="$IFS"
IFS=","
SERVERS=($SERVER_VAR)
PASSWORDS=($PWDS_VAR)
IFS="$OLD_IFS"
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
        ssh root@$SERVER $REMOTE_PATH/auto-install-package/install.sh $SERVER_VAR $SERVER  
    done
}

# 入口
main(){
    init
    ssh_copy_id_all
    ssh_login
}

main
