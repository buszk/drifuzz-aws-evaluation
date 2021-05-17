#!/bin/bash
# WiFi driver test

# targets=(
#     "ath10k_pci"
#     "ath9k"
#     "rtwpci"
# )

# concolic_configs=(1 0)
# model_configs=(1 0)

# Ethernet driver test
targets=(
    # "8139cp"
    # "atlantic"
    "snic"
    #"stmmac_pci"
)

concolic_configs=(1 0)
model_configs=(0)
niter=3
max_instances=1

function finish {
    echo
    echo "Terminating. Please wait..."
    ./terminate_all.sh
}
trap finish EXIT

# Cleanup and setup
cnt=0
rm -rf generated/*
rm -f run_instances.log
mkdir -p generated

function add_to_genearte {
    # Add to experiment list if we don't have the result yet
    if ! [ -f ~/Workspace/git/file-storage/files/result-${1}-${2}-${3}-${4}.tar ]; then
        echo "run_experiment $1 $2 $3 $4" >> generated/all_experiments.sh
    fi
}

function max_experiment {
    max_instances=$1
    tl=$(wc -l <generated/all_experiments.sh)
    nl=$(($(($tl+$max_instances-1))/$max_instances))
    echo "$nl"
}

function split_experiments {
    max_instances=$1
    nl=$(max_experiment $max_instances)
    echo "each instance gets $nl lines"
    for i in $(seq $max_instances); do
        cp base.sh.template generated/payload_${i}.sh
        sl=$((1+$nl*$i-$nl))
        el=$(($nl*$i))
        echo "Line start: $sl, end: $el"
        sed -n "${sl},${el}p" generated/all_experiments.sh >> generated/payload_${i}.sh
    done
}

# Add experiments
for i in $(seq $niter); do
    for t in ${targets[*]}; do
        for cc in ${concolic_configs[*]}; do
            for mc in ${model_configs[*]}; do
                cnt=$(($cnt+1))
                cntstr=$(printf "%3d" $cnt)
                echo "[Drifuzz AWS][$cntstr] Registering experiment ${t} ${cc} ${mc} ${i}"
                add_to_genearte $t $cc $mc $i
            done
        done
    done
done

# Separate to multiple instances
split_experiments $max_instances

totaltime=$((1200+7800*$(max_experiment $max_instances)))
echo "Total time is $(($totaltime/60)) minutes"
# exit 0
# Start instances
for i in $(seq $max_instances); do
    userinput=generated/payload_${i}.sh
    aws ec2 run-instances \
        --image-id "ami-01e7ca2ef94a0ae86" \
        --count 1 \
        --instance-type c5.metal \
        --key-name amz \
        --security-group-ids sg-09fc27778f02c34a0 \
        --instance-market-options file://spot-options.json \
        --block-device-mappings file://mapping.json \
        --user-data file://$userinput 2>&1 >run_instances.log
    if [ $? -ne 0 ]; then
        echo "Launch instance encountered error"
        echo "tail run_instances.log"
        echo $(tail run_instances.log)
        exit 1
    fi
    # Wa
    # sleep 120
done

# Wait for result
# 20 minute + 2 hour 10 minute * N experiment
sleep $totaltime
./terminate_all.sh

