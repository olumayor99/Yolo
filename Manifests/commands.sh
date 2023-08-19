#!/bin/bash

# Add Custer to kubeconfig
aws eks update-kubeconfig --region us-east-1 --name Yolo-EKS

# Deploy metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Manually create horizontal pod autoscaler. IaC is preferred.
kubectl autoscale deployment frontend --cpu-percent=5 --min=1 --max=8

kubectl autoscale deployment backend --cpu-percent=5 --min=1 --max=8

# Test horizontal pod autoscaler
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://frontend-service; done"

kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://backend-service; done"

# Download Cluster Autoscaler
wget https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Test Cluster Autoscaler
kubectl scale --replicas=60 deployment frontend

kubectl scale --replicas=60 deployment backend

# Helm
helm create yolo_app

helm template yolo_app

helm lint yolo_app

helm install YoloRelease yolo_app