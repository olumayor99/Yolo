terraform {
  backend "s3" {
    bucket  = "yolo-task-bucket-to-store-terraform-remote-state-s3"
    key     = "version3.tfstate"
    region  = "us-east-1"
    encrypt = "true"
    dynamodb_table = "yolo-task-table-to-store-terraform-remote-state"
  }
}