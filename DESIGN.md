Why vpc module has private, public, and intra subnets
1. Public subnets for loadbalancers, private subnets for kubernetes nodes, and intra subnets for EKS controlplane resources. This is the recommended way by AWS.


Why the route tables and Internet gateways were created automatically due to using VPC module
1. The VPC module automatically provisions the route tables with the least permissions needed.
2. The EKS module automatically creates and configures the recommended security groups for the EKS cluster.


How to install and test HPA and CA

Metrics server for horizontal pod autoscaler
```sh
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://frontend-service; done"

kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://backend-service; done"

```
Then run `kubectl get pods`

Cluster autoscaler

```sh
kubectl scale --replicas=60 deployment frontend

kubectl scale --replicas=60 deployment backend
```

then run `kubectl get nodes`


Using external DNS instead of the traditional ingress controller
1. It automatically connects loadbalancers to Hosted Zones, thereby eliminating the need for manual configuration which might be tedious and/or problem-ridden.


How I converted the kubernetes manifests to Helm charts and the improvements needed
1. I used the `helm create CHART` command
2. I edited the kubernetes manifests to use variables for the properties I feel can be edited or customised
3. I created the variables in the values.yaml file for the created helm chart.


Developing for github actions later


Creating multiple users for the EKS cluster


Why s3 and dynamo were used for remote backend. Any better alternatives?
1. They are easier to implement for my use-case.
2. I don't have a terraform cloud account subscription.
3. Storing the state locally is not even an option.


Why I didn't use terraform workspaces
1. Terraform uses the same backend for multiple workspaces. This can be an issue because of state locking due to the fact that other teams might want to deploy at the same time.
2. If a team corrupts the state in a workspace, it will affect all other workspaces and recovering the state might be tedious.


Why I used a single namespace
1. Ease of managing resources
2. It is a minimal application


Why I need to create subcharts instead of what I did
1. When the number of deployments get larger, using a single chart will be tedious most especially when mulitple teams are working on different parts and are in different stages of development.
2. Ease of releasing apps.

How to improve cluster security
1. Run containers with non-root users 
2. Deactivate privilege escalation
3. Add `- NET_RAW` and `- ALL` to spec.container[0].securityContext.capabilities.drop in deployments.

Now describe the issue with the frontend pod not being able to access the backend pod

Outline monitoring solutions???


This is still a work in progress.