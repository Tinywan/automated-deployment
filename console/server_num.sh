#!/bin/bash
SERVERS=('192.168.1.1' '192.168.1.2')
echo '-------------'${#SERVERS[@]}
for index in ${SERVERS[@]}
do
  echo '---------'$index
done

  for(( count=0;count<=${#SERVERS[@]}-1;count+=1 ))

   do
    array_name[$count]=$count
    echo '-----------'$count

   done
echo 'array_name == '${#array_name[@]}

for index in ${array_name[@]}
do
  echo '------array_name nums---'$index
done
