variable "prefix" {
  default     = "Yolo"
  description = "Prefix resource names"
}
variable "aws_region" {
  default     = "us-east-1"
  description = "VPC region"
}
variable "vpc_cidr" {
  default     = "10.10.0.0/16"
  description = "VPC CIDR range"
}
variable "domain_name" {
   type= string
   description= "domain name"
   default= "drayco.com" # Replace with your own domain name
}
