resource "aws_route53_zone" "ingress-nginx" {
  name = var.domain_name
}