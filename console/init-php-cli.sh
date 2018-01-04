#!/bin/bash
echo "init start ..............................."
SERVERS=$1
PWDS=$2
OLD_IFS="$IFS" 
IFS="," 
SERVER_ARR=($SERVERS) 
PWD_ARR=($PWDS) 
IFS="$OLD_IFS"
 
for server in ${SERVER_ARR[@]} 
do 
    echo "server -- $server" 
done

for index in ${PWD_ARR[@]}
do
    echo "pwd ---- $index" 
done

echo "init fininshed .................................."
echo "start Install 请耐心等待哦！！...................."
