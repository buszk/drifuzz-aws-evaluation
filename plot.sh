#!/bin/bash

target=$1
rm -rf results/*
mkdir -p results
pushd $(pwd)
cd results
for tf in ~/Workspace/git/file-storage/files/result-${target}*.tar; do
    tar xf $tf
    # Remove large log files
    find . -iname "*.log" -delete
done
popd
./plot.py $target
