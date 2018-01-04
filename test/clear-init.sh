#!/bin/bash
echo "----------------clear init start -------------------------------------"
SERVER_VAR=$1
OLD_IFS="$IFS"
IFS=","
SERVERS=($SERVER_VAR)
IFS="$OLD_IFS"
#SERVER_NUMS=(0 1)
function clear_init(){
   for i in ${SERVERS[@]}
   do
	echo $i ' clearing ...'
	sleep 3
	ssh-keygen -f "/home/www/.ssh/known_hosts" -R $i
   done
}

clear_init
echo "----------------clear init end -------------------------------------"

