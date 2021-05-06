#!/bin/bash
targets=(
    "ath10k_pci"
    "ath9k"
    "rtwpci"
)

concolic_configs=(1 0)
model_configs=(1 0)
niter=4

rm -f run_instances.log
mkdir -p generated
for i in $(seq $niter); do
    for t in ${targets[*]}; do
        for cc in ${concolic_configs[*]}; do
            for mc in ${model_configs[*]}; do
                echo $t $cc $mc
                echo "${t}_${cc}_${mc}.sh"
                userinput=generated/${t}_${cc}_${mc}_${i}.sh
                sed "s/{target}/$t/g;s/{concolic}/$cc/g;s/{model}/$mc/g;s/{iteration}/$i/g" \
                        base.sh.template > $userinput
                aws ec2 run-instances \
                    --image-id "ami-01e7ca2ef94a0ae86" \
                    --count 1 \
                    --instance-type c5.metal \
                    --key-name amz \
                    --security-group-ids sg-09fc27778f02c34a0 \
                    --instance-market-options file://spot-options.json \
                    --block-device-mappings file://mapping.json \
                    --user-data file://$userinput 2>&1| tee -a run_instances.log
                if [ $? -ne 0 ]; then
                    echo "Launch instance encountered error"
                    echo "tail run_instances.log"
                    echo $(tail run_instances.log)
                    exit 1
                fi
                # Test code
                sleep 9000
                ./terminate_all.sh
                exit 0
            done
        done
    done
done

sleep 9000
./template_all.sh

