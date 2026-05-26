#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-angira-fitness-cluster}"
AWS_REGION="${AWS_REGION:-ap-south-2}"
NODEGROUP_NAME="${NODEGROUP_NAME:-angira-nodegroup}"
NODE_TYPE="${NODE_TYPE:-t3.medium}"
K8S_VERSION="${K8S_VERSION:-1.31}"

echo "Updating packages and installing prerequisites..."
sudo apt update -y
sudo apt install -y unzip curl tar gzip

echo "Installing AWS CLI v2..."
if ! command -v aws >/dev/null 2>&1; then
  tmp_dir="$(mktemp -d)"
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$tmp_dir/awscliv2.zip"
  unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
  sudo "$tmp_dir/aws/install"
else
  echo "AWS CLI is already installed."
fi
aws --version

echo "Installing kubectl..."
if ! command -v kubectl >/dev/null 2>&1; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
else
  echo "kubectl is already installed."
fi
kubectl version --client

echo "Installing eksctl..."
if ! command -v eksctl >/dev/null 2>&1; then
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz
  sudo mv eksctl /usr/local/bin
else
  echo "eksctl is already installed."
fi
eksctl version

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "AWS credentials are not configured. Run 'aws configure' first, then run this script again."
  exit 1
fi

echo "Using AWS account:"
aws sts get-caller-identity

echo "Creating EKS cluster if it does not exist..."
if ! eksctl get cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  eksctl create cluster \
    --name "$CLUSTER_NAME" \
    --version "$K8S_VERSION" \
    --region "$AWS_REGION" \
    --nodegroup-name "$NODEGROUP_NAME" \
    --node-type "$NODE_TYPE" \
    --nodes 2 \
    --nodes-min 2 \
    --nodes-max 3 \
    --managed
else
  echo "Cluster $CLUSTER_NAME already exists."
fi

echo "Updating kubeconfig..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo "Applying Kubernetes manifests..."
kubectl apply -f Configmap.yaml
kubectl apply -f deployment-fitness.yaml

if [ -f loadbalancer.yaml ]; then
  kubectl apply -f loadbalancer.yaml
fi

echo "Pods:"
kubectl get pods -o wide

echo "Services:"
kubectl get svc --all-namespaces

echo "Nodes:"
kubectl get nodes -o wide

echo "LoadBalancer service details:"
kubectl get svc fitness-loadbalancer-service 2>/dev/null || true

external_address="$(kubectl get svc fitness-loadbalancer-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
if [ -z "$external_address" ]; then
  external_address="$(kubectl get svc fitness-loadbalancer-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
fi

if [ -n "$external_address" ]; then
  echo "Open your app at: http://$external_address"
else
  echo "LoadBalancer external address is still pending. Run: kubectl get svc fitness-loadbalancer-service -w"
fi
