terraform {
  backend "s3" {
    bucket  = "yolo-task-bucket-to-store-terraform-remote-state-s3" # The S3 bucket name
    key     = "version3.tfstate" # Customise the prefix of ".tfstate", or you can leave it as it is
    region  = "us-east-1" # The region the S3 bucket was deployed in
    encrypt = "true"
    dynamodb_table = "yolo-task-table-to-store-terraform-remote-state"
  }
}