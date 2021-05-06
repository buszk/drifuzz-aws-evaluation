#!/bin/bash

result=$(aws ec2 describe-instances)
ids=($(echo $result | jq -r ".Reservations[].Instances[].InstanceId"))
states=($(echo $result | jq -r ".Reservations[].Instances[].State.Name"))
ips=($(echo $result | jq -r ".Reservations[].Instances[].NetworkInterfaces[].Association.PublicIp"))
len=${#ids[@]}

# echo len: $len
for i in $(seq 0 $(($len-1))); do
    echo ${ids[$i]} ${states[$i]}
done
echo "IP addresses in use:"
echo $ips