#!/bin/bash

function plot_one {
    target=$1
    mkdir -p results
    pushd $(pwd) >/dev/null
    cd results
    # for tf in ~/Workspace/git/file-storage/files/result-${target}*.tar; do
    #     if [ $tf != "~/Workspace/git/file-storage/files/result-${target}*.tar" ]; then
    #         tar xf $tf
    #         # Remove large log files
    #         # find . -iname "*.log" -delete
    #     fi
    # done
    popd >/dev/null
    mkdir -p plots
    ./plot.py $target
}

targets=(
    # Ethernet
    "8139cp"
    "atlantic"
    "snic"
    "stmmac_pci"
    # WiFi
    "ath9k"
    "ath10k_pci"
    "rtwpci"
)

# rm -rf results/*

for target in ${targets[*]}; do
    if [ $1 == "all" ]; then
        plot_one $target
    elif [ $1 == $target]; then
        plot_one $target
    fi
done
