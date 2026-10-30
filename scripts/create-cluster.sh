#!/usr/bin/env bash

DIR=$(dirname "$0")
CLUSTER_CONFIG="cluster-config.yaml"

[[ ! -f $DIR/$CLUSTER_CONFIG ]] && echo "'$DIR/$CLUSTER_CONFIG' does not exists, quiting..." && exit

read -n 1 -p "Are you sure want to create cluster with config: '$DIR/$CLUSTER_CONFIG'? " choice
echo
if [[ $choice == "y" || $choice == "Y" ]]; then
    echo $choice
    # eksctl create cluster -f $DIR/$CLUSTER_CONFIG
fi
