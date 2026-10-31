#!/usr/bin/env bash
set -e

#####################
# Script Related
#####################
DIR=$(dirname "$0")
CLUSTER_CONFIG="cluster-config.yaml"
CLUSTER_CONFIG_FILE="${DIR}/${CLUSTER_CONFIG}"
[[ ! -f $CLUSTER_CONFIG_FILE ]] && echo "Cluster config file ($CLUSTER_CONFIG_FILE) doesn't exist, aborting..." && exit

#####################
# AWS Related
#####################
CLUSTER_NAME=$(yq '.metadata.name' "$CLUSTER_CONFIG_FILE")
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CLUSTER_REGION=$(yq '.metadata.region' "$CLUSTER_CONFIG_FILE")
SERVICE_ACCOUNT_NAME="aws-alb-svc-acc"
AWS_ALB_POLICY="aws-alb-policy"
AWS_ALB_ROLE="aws-alb-role"
TRUST_RELATIONSHIP_FILE="${DIR}/aws-alb-role-trust-relationship.json"
[[ ! -f $TRUST_RELATIONSHIP_FILE ]] && echo "Trust Relationship file for ALB Role ($TRUST_RELATIONSHIP_FILE) doesn't exist, aborting..." && exit

#####################
# Helper Functions
#####################
function print_with_seperator {
    msg="$*"
    msg_len=${#msg}
    local SEPERATOR=$(python3 -c "print('-' * ($msg_len + 5))")

    printf "%s\n" "$SEPERATOR"
    printf "%s...\n" "$msg"
    printf "%s\n" "$SEPERATOR"
    echo
}

function alb_role_exists {
    aws iam get-role --role-name "$AWS_ALB_ROLE" > /dev/null 2>&1
}

# usage: create_alb_policy <policy_name>
function create_alb_policy {

    # download iam policy for aws alb
    local POLICY_FILE="iam-policy-aws-alb.json"
    curl -fsSLo "$POLICY_FILE" https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/main/docs/install/iam_policy.json

    # create iam policy from the downloaded policy file
    aws iam create-policy --policy-name $AWS_ALB_POLICY --policy-document file://"${POLICY_FILE}"
}

function create_alb_role {

    # create policy for aws alb
    create_alb_policy "$AWS_ALB_POLICY"

    # create role for alb
    aws iam create-role --role-name "$AWS_ALB_ROLE" --assume-role-policy-document file://"${TRUST_RELATIONSHIP_FILE}"

    attach alb policy to alb role
    aws iam attach-role-policy --role-name "$AWS_ALB_ROLE" --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${AWS_ALB_POLICY}"
}

function install_alb_controller {
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update eks
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=$SERVICE_ACCOUNT_NAME
}

#####################
# Driver Code
#####################

#####################
# AWS Role Setup (Onetime)
#####################

# role for alb controller
print_with_seperator Checking "'$AWS_ALB_ROLE'" exists
if alb_role_exists; then
    echo "Role for ALB Controller exists, skipping role creation..."
else
    echo "Role for ALB Controller doesn't exists, creating..." && create_alb_role
fi


#####################
# Installation
#####################

# set kubeconfig current context
aws eks update-kubeconfig --region $CLUSTER_REGION --name $CLUSTER_NAME

# install gateway api crds
print_with_seperator Installing K8s Gateway API CRDS
kubectl apply --server-side=true -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.0/standard-install.yaml

# install aws alb gateway api crds
print_with_seperator Installing AWS ALB Gateway API CRDS
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/refs/heads/main/config/crd/gateway/gateway-crds.yaml

# create service account for alb controller
print_with_seperator Creating ServiceAccount for ALB Controller
kubectl create serviceaccount $SERVICE_ACCOUNT_NAME -n kube-system

# install pod identity addon
print_with_seperator Installing EKS Pod Identity Agent
aws eks create-addon --cluster-name $CLUSTER_NAME --addon-name eks-pod-identity-agent

# create pod identity association
print_with_seperator Creating Pod Identity Association of ALB Role
aws eks create-pod-identity-association \
  --cluster-name $CLUSTER_NAME \
  --role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${AWS_ALB_ROLE}" \
  --namespace kube-system \
  --service-account $SERVICE_ACCOUNT_NAME

# install helm charts
print_with_seperator Installing ALB Controller using HELM
if install_alb_controller > /dev/null 2>&1; then
    echo Installation Successfull! Happy Birthday!
else
    echo Something Went Wrong...
fi
