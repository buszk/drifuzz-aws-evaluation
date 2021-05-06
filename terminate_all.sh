#/bin/bash

instances=$(aws ec2 describe-instances |jq -r ".Reservations[].Instances[].InstanceId")

for instance in $instances; do
    aws ec2 terminate-instances \
        --instance-ids ${instance} | jq -r ".TerminatingInstances[].InstanceId"
done