# Yolo

A Sportsbook DevOps Engineer Task. It consists of a minimal frontend and backend (both written in Elixir using Phoenix, Cowboy, Plug, and Php). It is configured to be deployed to an EKS cluster on AWS using Terraform and Helm.


## Demo**

![Demo!](./assets/images/yollo_front.png)

**There is an issue with the frontend image. See "Issues" section in [DESIGN.md](DESIGN.md) for details.


## Architecture

![Archi!](./assets/images/archi.png)

For detailed information about the architecture, design considerations, and also design improvements (security and monitoring solutions), please visit [DESIGN.md](DESIGN.md).


## Deployment

First, you need to meet/get the following requirements. Click on the links to take you to the respective pages that will describe how to install and set them up properly.

1. An [AWS](https://aws.amazon.com) account.
2. [AWSCLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. [Kubectl](https://kubernetes.io/docs/tasks/tools/)
4. [Helm](https://helm.sh/docs/intro/install/)
5. [Terraform](https://developer.hashicorp.com/terraform/downloads)
   
Once the requirements are met, you need to create an ACCESS KEY on your AWS account and configure AWSCLI to use it. You can use [this](https://docs.aws.amazon.com/cli/latest/userguide/cli-authentication-user.html) tutorial if you don't know how to go about that.

The next step is to clone this repository and go into the folder using the following commands in your preferred terminal:

```sh
git clone https://github.com/olumayor99/Yolo.git
cd Yolo
```


Here is the folder structure of the repository:

```sh
$ tree
.
|-- DESIGN.md
|-- HelmCharts
|   `-- yolo_app
|       |-- Chart.yaml
|       |-- charts
|       |-- templates
|       |   |-- _helpers.tpl
|       |   |-- configmaps.yaml
|       |   |-- deployments.yaml
|       |   |-- external-dns.yaml
|       |   |-- horizontal-pod-autoscaler.yaml
|       |   |-- metrics-server.yaml
|       |   `-- services.yaml
|       `-- values.yaml
|-- Infrastructure
|   |-- backend.tf
|   |-- ca.tf
|   |-- dns.tf
|   |-- eks.tf
|   |-- iam.tf
|   |-- outputs.tf
|   |-- plan.json
|   |-- plan.out
|   |-- providers.tf
|   |-- variables.tf
|   |-- versions.tf
|   `-- vpc.tf
|-- Manifests
|   |-- cluster-autoscaler.yaml
|   |-- commands.sh
|   |-- deployments.yaml
|   |-- external-dns.yaml
|   |-- horizontal-pod-autoscaler.yaml
|   |-- metrics-server.yaml
|   `-- services.yaml
|-- README.md
|-- RemoteState
|   |-- backend.tf
|   |-- terraform.tfstate
|   `-- terraform.tfstate.backup
`-- assets
    `-- images
        |-- archi.png
        |-- cluster.png
        |-- cmerr.png
        |-- err.png
        |-- hz.png
        |-- interr.png
        |-- kerr.png
        |-- ns.png
        |-- perr.png
        |-- tree.png
        `-- yollo_front.png

9 directories, 44 files

```


We need to deploy the infrastructure before we can deploy the application itself. To deploy the infrastructure, we first need to customise some variables such as the names of the resources, the region to deploy them to, and a bunch of others. Run the following commands:

```sh
cd Infrastructure
vi variables.tf #**
```
**You can edit the file with any other editor you have, I just prefer using vi.


The [variables.tf](Infrastructure/variables.tf) file contains all the variables that can be cutomised to your taste. Below is how it looks.

```tf
variable "prefix" {
  type= string
  default     = "Yolo"
  description = "Prefix resource names"
}
variable "aws_region" {
  type= string
  default     = "us-east-1"
  description = "VPC region"
}
variable "vpc_cidr" {
  type= string
  default     = "10.10.0.0/16"
  description = "VPC CIDR range"
}
variable "domain_name" {
   type= string
   default= "drayco.com" # Replace with your own domain name
   description= "domain name"

}
```


After editing it to your taste, you need to configure the terraform backend. In this case, we're using an S3 bucket to store the state, and a DynamoDB table to lock the state while deployment is ongoing. I'll asume that you have neither of these created, so I've written scripts to enable you provision them (if you want to create them manually and you don't know how to, use [this](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html) article, and [this](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/getting-started-step-1.html) too) First you need to customise the script. Run the following commands (I'm assuming you're still in the [Infrastructure](Infrastructure) directory):

```sh
cd ../RemoteState
vi backend.tf 
```


It should display a file like the one below

```tf
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "yolo-task-bucket-to-store-terraform-remote-state-s3" # Change this to a very unique name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  name     = "yolo-task-table-to-store-terraform-remote-state"  # Edit this to what you want
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```


Save that, then head back to the [Infrastructure](Infrastructure) folder using 

```sh
cd ../Infrastructure
```


and edit the [backend.tf](Infrastructure/backend.tf) using

```sh
vi backend.tf
```


Replace the key if you wish. Note that it must end with the ".tfstate" extension for it to work.

```tf
terraform {
  backend "s3" {
    bucket  = "yolo-task-bucket-to-store-terraform-remote-state-s3" # The S3 bucket name
    key     = "version3.tfstate" # Customise the prefix of ".tfstate", or you can leave it as it is
    region  = "us-east-1" # The region the S3 bucket was deployed in
    encrypt = "true"
    dynamodb_table = "yolo-task-table-to-store-terraform-remote-state"
  }
}
```


Once that's done, confirm that you're in the [Infrastructure](Infrastructure) folder, then initialize the terraform backend and install the modules/packages using 

```sh
terraform init
```


It is successful when you get a message like the one below:

```sh
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```


View the plan of the resources it will deploy using:

```sh
terraform plan
```


After seeing the plan and confirming the resources it will deploy, run the following command, and respond "yes" to the prompt to deploy the resources.

```sh
terraform apply
```


You can also run the following command to skip the prompt.

```sh
terraform apply --auto-approve
```


If it deploys all the resources successfully, you should get a response similar to the one below:

```sh
Releasing state lock. This may take a few moments...

Apply complete! Resources: 79 added, 0 changed, 0 destroyed.

Outputs:

cluster_endpoint = "https://3B11B9E7577EEBF8FB6EAD3C2425A976.gr7.us-east-1.eks.amazonaws.com"
cluster_name = "Yolo-EKS"
cluster_region = "us-east-1"
cluster_security_group_id = "sg-04d38b0c29a6f11c4"
domain_name = "drayco.com"
hosted_zone_id = "Z01691221PDTF4OGQN1U3"
oidc_issuer = "oidc.eks.us-east-1.amazonaws.com/id/3B11B9E7577EEBF8FB6EAD3C2425A976"
prefix = "Yolo"
private_subnets = [
  "subnet-0841712b4a67c22e5",
  "subnet-045d1f4790ce3bf96",
  "subnet-0de7b49a1bdc81ac4",
]
public_subnets = [
  "subnet-000993cc2b6f3c61b",
  "subnet-001517377be3f67ce",
  "subnet-0d34067ebc5167856",
]
vpc_id = "vpc-0db51720f607ec9fd"
vpc_name = "Yolo-vpc"

```


The outputs displayed here are defined in the [outputs.tf](Infrastructure/outputs.tf) file. Please note the value of the `domain_name`, `hosted_zone_id`, `cluster_name`, and `cluster_region` fields, they will be needed in one of the next steps. The other outputs can also be saved, but they aren't really needed for now.

The scripts in the [Infrastructure](Infrastructure) directory will deploy a VPC, an EKS cluster, and all the other needed resources such as an internet gateway, subnets, DNS Hosted Zone, security groups, NAT gateways, Node Groups, Service Accounts, etc. These resources are essential for the app to function properly.

Now you need to add the cluster to your .kubeconfig file. Use the following command:

```sh
aws eks update-kubeconfig --region us-east-1 --name Yolo-EKS
```

`us-east-1` should be replaced with the value of the `cluster_region` output, and `Yolo-EKS` with the value of the `cluster_name` output respectively.


The next step is to deploy the app to the cluster. This is done using the helm chart located in the [HelmCharts](HelmCharts) directory. Before deployment though, we need to edit the [values.yaml](HelmCharts/yolo_app/values.yaml) file. Run the following commands to do that:

```sh
cd ../HelmCharts/yolo_app/
vi values.yaml
```


Its contents are similar to the following

```yaml
# Default values for yolo_app.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

# Frontend Deployment
frontend:
  metadata:
    name: frontend
  replicaCount: 2
  containerName: frontend-container
  image:
    repository: public.ecr.aws/v5d9e1r0/yolo/yolo_hello_front:v0.0.1
    pullPolicy: Always
    selectorLabels:
      app: frontend
    labels:
      app: frontend

# Backend Deployment
backend:
  metadata:
    name: backend
  replicaCount: 2
  containerName: backend-container
  image:
    repository: public.ecr.aws/v5d9e1r0/yolo/yolo_hello_back:v0.0.1
    pullPolicy: Always
    selectorLabels:
      app: backend
    labels:
      app: backend

# Frontend Service
frontendService:
  name: frontend-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: drayco.com
  selector:
    app: frontend
  type: LoadBalancer

# Backend Service
backendService:
  name: backend-service
  selector:
    app: backend
  type: ClusterIP

# Frontend Horizontal Pod Autoscaler
frontendHPA:
  minReplicas: 2
  maxReplicas: 100
  averageUtilization: 10

# Backendend Horizontal Pod Autoscaler
backendHPA:
  minReplicas: 2
  maxReplicas: 100
  averageUtilization: 10

# ExternalDNS
externalDNS:
  domainFilter: drayco.com
  txtOwnerID: Z046868710106H7HIXYYF
  
# Frontend Configmap
frontendCMData:
  BACKEND_URL: http://backend-service


```


Replace the `clusterName` value with the `cluster_name` output value that you noted earlier, `domainFilter` with the `domain_name` output value, and then the value of `txtOwnerID` with the value of the `hosted_zone_id`.

After completing this step, run the following command to view the helm templates:

```sh
helm template yolo_app
```


then run this to make sure the helm templates are properly linted

```sh
helm lint yolo_app
```


and then deploy the app with

```sh
helm install yolo yolo_app
```


`yolo` is the name of the release, wile `yolo_app` is the name of the chart. You can change `yolo` to any name you want, but you can't change the name of the chart.

After running this command, you should get a response similar to the one below:

```sh
$ helm install yolo yolo_app
NAME: yolo
LAST DEPLOYED: Sun Aug 20 05:18:02 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

```


Now when you run `kubectl get all -A`, you should get a response similar to the image below:


```sh
$ kubectl get all -A
NAMESPACE     NAME                                                             READY   STATUS    RESTARTS   AGE
default       pod/backend-7b4c4fc9fb-8frmf                                     1/1     Running   0          35s
default       pod/backend-7b4c4fc9fb-tx6f8                                     1/1     Running   0          35s
default       pod/external-dns-586d768cdc-p2nwm                                1/1     Running   0          35s
default       pod/frontend-fbf844655-cqkk2                                     1/1     Running   0          35s
default       pod/frontend-fbf844655-rjt4j                                     1/1     Running   0          35s
kube-system   pod/aws-node-2s8ck                                               1/1     Running   0          7m11s
kube-system   pod/aws-node-48lht                                               1/1     Running   0          6m50s
kube-system   pod/cluster-autoscaler-aws-cluster-autoscaler-779c678f46-fhhzt   1/1     Running   0          8m21s
kube-system   pod/coredns-79df7fff65-fvhvq                                     1/1     Running   0          12m
kube-system   pod/coredns-79df7fff65-zzx62                                     1/1     Running   0          12m
kube-system   pod/kube-proxy-8lvtn                                             1/1     Running   0          7m11s
kube-system   pod/kube-proxy-tslpk                                             1/1     Running   0          6m50s
kube-system   pod/metrics-server-5d875656f5-95hx6                              1/1     Running   0          35s

NAMESPACE     NAME                                                TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)         AGE
default       service/backend-service                             ClusterIP      172.20.195.199   <none>                                                                   80/TCP          37s
default       service/frontend-service                            LoadBalancer   172.20.236.140   a0045ab24dd1c44d2afbb3b5da011531-754554442.us-east-1.elb.amazonaws.com   80:30063/TCP    37s
default       service/kubernetes                                  ClusterIP      172.20.0.1       <none>                                                                   443/TCP         12m
kube-system   service/cluster-autoscaler-aws-cluster-autoscaler   ClusterIP      172.20.110.51    <none>                                                                   8085/TCP        8m22s
kube-system   service/kube-dns                                    ClusterIP      172.20.0.10      <none>                                                                   53/UDP,53/TCP   12m
kube-system   service/metrics-server                              ClusterIP      172.20.254.160   <none>                                                                   443/TCP         37s

NAMESPACE     NAME                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
kube-system   daemonset.apps/aws-node     2         2         2       2            2           <none>          12m
kube-system   daemonset.apps/kube-proxy   2         2         2       2            2           <none>          12m

NAMESPACE     NAME                                                        READY   UP-TO-DATE   AVAILABLE   AGE
default       deployment.apps/backend                                     2/2     2            2           37s
default       deployment.apps/external-dns                                1/1     1            1           37s
default       deployment.apps/frontend                                    2/2     2            2           37s
kube-system   deployment.apps/cluster-autoscaler-aws-cluster-autoscaler   1/1     1            1           8m23s
kube-system   deployment.apps/coredns                                     2/2     2            2           12m
kube-system   deployment.apps/metrics-server                              1/1     1            1           37s

NAMESPACE     NAME                                                                   DESIRED   CURRENT   READY   AGE
default       replicaset.apps/backend-7b4c4fc9fb                                     2         2         2       37s
default       replicaset.apps/external-dns-586d768cdc                                1         1         1       37s
default       replicaset.apps/frontend-fbf844655                                     2         2         2       37s
kube-system   replicaset.apps/cluster-autoscaler-aws-cluster-autoscaler-779c678f46   1         1         1       8m23s
kube-system   replicaset.apps/coredns-79df7fff65                                     2         2         2       12m
kube-system   replicaset.apps/metrics-server-5d875656f5                              1         1         1       37s

NAMESPACE   NAME                                           REFERENCE             TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
default     horizontalpodautoscaler.autoscaling/backend    Deployment/backend    <unknown>/10%   2         100       2          37s
default     horizontalpodautoscaler.autoscaling/frontend   Deployment/frontend   <unknown>/10%   2         100       2          37s

```


## Viewing the app

If the domain name set in the `domain_name` variable in [variables.tf](Infrastructure/variables.tf)  is managed by Route53, just input it in a browser and you should be able to view the page. Follow the steps below if it isn't.

1. In your AWS account, go to Route53, then click on `Hosted Zones`
   
   ![hz!](./assets/images/hz.png)

2. Click on the domain name you used in your terraform code, and copy the highlighted nameservers. They are in the NS record.
   
   ![ns!](./assets/images/ns.png)

3. Take them to the domain name registrar of your domain name and add then to the domain name's settings. Wait for a while and visit the domain name in a browser and you should be able to access the page.


## Destroy resources

1. Run `helm delete yolo` and wait for it to finish.
2. Then go into the [Infrastructure](Infrastructure) folder and run `terraform destroy`, at the prompt, respond "yes".
3. You can also run `terraform destroy --auto-approve` to skip the propmt and destroy the infrastructure.
4. Sometimes the infrastructure isn't destroyed completely because of the DNS Hosted Zone record.
   
   ```sh
   Error: deleting Route53 Hosted Zone (Z0090123D8QUDP819VKC): HostedZoneNotEmpty: The specified hosted zone contains non-required resource record sets and so cannot be deleted. status code: 400, request id: d5a077ad-b731-449b-b945-dd47fcaf2d51
   ```
   
   Delete the highlighted records (`A`, and `TXT`) below and run step 2 or step 3 again, it will destroy all the resources completely.
   
   ![err!](./assets/images/err.png)

5. Then go to the [RemoteState](RemoteState) dierectory and run step 2 or step 3 to delete the backend. If you created them manually, then go into your account and delete them manually.