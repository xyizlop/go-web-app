#!/usr/bin/env bash

DIR=$(dirname "$0")
CLUSTER_CONFIG="cluster-config.yaml"
CLUSTER_CONFIG_FILE="${DIR}/${CLUSTER_CONFIG}"
[[ ! -f $CLUSTER_CONFIG_FILE ]] && echo "Cluster config file ($CLUSTER_CONFIG_FILE) doesn't exist, aborting..." && exit

[[ ! -f $DIR/$CLUSTER_CONFIG ]] && echo "'$DIR/$CLUSTER_CONFIG' does not exists, quiting..." && exit

read -n 1 -p "Are you sure want to create cluster with config: '$DIR/$CLUSTER_CONFIG'? " choice
echo
if [[ $choice == "y" || $choice == "Y" ]]; then
    eksctl create cluster -f "$CLUSTER_CONFIG_FILE"
else
    echo "You choose not to create cluster, exiting..."
fi
