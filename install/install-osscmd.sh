#!/bin/bash
echo '输入 1 到 4 之间的数字:'
echo '你输入的数字为:'
SERVER=$1
SERVER_ARR=('192.168.1.181' '192.168.1.11' '192.168.1.123')
#exit 1
case $SERVER in
    ${SERVER_ARR[0]})  echo '你选择了 1'
    ;;
    ${SERVER_ARR[1]})  echo '你选择了 2'
    ;;
    ${SERVER_ARR[2]})  echo '你选择了 3'
    ;;
    ${SERVER_ARR[4]})  echo '你选择了 4'
    ;;
    *)  echo '你没有输入 1 到 4 之间的数字'
    ;;
esac
