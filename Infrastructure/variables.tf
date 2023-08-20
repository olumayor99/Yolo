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
