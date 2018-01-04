#!/bin/bash
FILE_NAME=/home/www/web/go-study-line/shell/auto-install/shell.log
echo "....................准备中.............."
sleep 3
while read line
do
  echo $line
  sleep 0.05
done < $FILE_NAME
echo "...........finished........................"
