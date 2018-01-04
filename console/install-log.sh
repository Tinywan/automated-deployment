#!/bin/bash
FILENAME=/home/www/web/go-study-line/shell/auto-install/shell.log
main(){
	while(true)
	do
	  
	sleep 2
	done
}
function while_read_LINE_bottm(){
	while read LINE
	do
		echo $LINE
	done < $FILENAME
}
while_read_LINE_bottm

