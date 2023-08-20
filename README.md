# Yolo
A Sportsbook DevOps Engineer Task. It consists of a minimal frontend and backend (both written in Elixir using Phoenix, Cowboy, Plug, and Php). It is configured to be deployed to AWS using Terraform and Helm.

### Demo**
![Demo!](./assets/images/yollo_front.png)


**There is an issue with the frontend image. See "Issues" section below for details.

## Deployment
First, you need to meet/get the following requirements. Click on the links to take you to the respective pages that will describe how to install and set them up properly.

1. An [AWS](https://aws.amazon.com) account.
2. [AWSCLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. [Kubectl](https://kubernetes.io/docs/tasks/tools/)
4. [Helm](https://helm.sh/docs/intro/install/)
5. [Terraform](https://developer.hashicorp.com/terraform/downloads)
   
Once the requirements are met, you need to create an ACCESS KEY on your AWS account and configure AWSCLI to use it. You can use [this](https://docs.aws.amazon.com/cli/latest/userguide/cli-authentication-user.html) tutorial if you don't know how to go about it.

The next step is to clone this repository and go into the folder using the following commands in your preferred terminal:

```sh
git clone https://github.com/olumayor99/Yolo.git
cd Yolo
```

Here is the folder structure of the repository:
![Tree!](./assets/images/tree.png)

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

After editing to your taste, you need to configure the terraform backend. In this case, we're using an S3 bucket to store the state, and a DynamoDB table to lock the state while deployment is ongoing. I'll asume that you have neither of these created, so I've written scripts to enable you provision them. First you need to customise the script. Run the following commands (assuming you're still in the Infrastructure directory):

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

Save that, and then head back to the [Infrastructure](Infrastructure) folder using 

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

Once all that is done, confirm that you're in the [Infrastructure](Infrastructure) folder, then initialize the terraform backend and install the modules using 

```sh
terraform init
```

Once that's done, run the following command to see the plan of the resources it will deploy.

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