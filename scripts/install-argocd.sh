#!/usr/bin/env bash
set -e

echo "Installing ArgoCD in 'argocd' namespace using HELM charts..."
# namespace
kubectl create namespace argocd

# clone repo
# good to clone at /tmp because it's not part of your project
cd /tmp
git clone https://github.com/argoproj/argo-helm.git
cd argo-helm/charts/argo-cd
helm dependency up # downloads dependencies from Chart.yaml

# install
helm install argocd . --values values.yaml -n argocd

echo "Installation successful"
echo "Use 'helm list -n argocd' for verification, Bye!"