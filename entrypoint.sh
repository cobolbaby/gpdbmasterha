#!/bin/bash
set -e

# 启动sshd
/usr/sbin/sshd

# ssh-keygen无回车生成公钥私钥对
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N "" -q

nodes=("mdw" "smdw")
for host in ${nodes[@]} 
do 
    sshpass -p "gpadmin" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub gpadmin@$host
done

while true; do sleep 60; ./gpfailover.sh; echo "gpfailover exit code: $?"; done

