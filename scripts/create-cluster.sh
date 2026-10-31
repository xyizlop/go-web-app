#!/usr/bin/env bash
set -e

DIR=$(dirname "$0")
CLUSTER_CONFIG="cluster-config.yaml"
CLUSTER_CONFIG_FILE="${DIR}/${CLUSTER_CONFIG}"
[[ ! -f $CLUSTER_CONFIG_FILE ]] && echo "Cluster config file ($CLUSTER_CONFIG_FILE) doesn't exist, aborting..." && exit

[[ ! -f $CLUSTER_CONFIG_FILE ]] && echo "'$CLUSTER_CONFIG_FILE' does not exists, quiting..." && exit

CLUSTER_NAME=$(yq '.metadata.name' "$CLUSTER_CONFIG_FILE")
CLUSTER_REGION=$(yq '.metadata.region' "$CLUSTER_CONFIG_FILE")

if eksctl get cluster --name $CLUSTER_NAME --region $CLUSTER_REGION >/dev/null 2>&1; then
    echo "EKS Cluster '$CLUSTER_NAME' exists, update '$CLUSTER_CONFIG_FILE' for new cluster, exiting..." &&     exit
fi

read -n 1 -p "Are you sure want to create cluster with config: '$CLUSTER_CONFIG_FILE'? " choice
echo
if [[ $choice == "y" || $choice == "Y" ]]; then
    eksctl create cluster -f "$CLUSTER_CONFIG_FILE"
else
    echo "You choose not to create cluster, exiting..."
fi
