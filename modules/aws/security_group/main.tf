# Child SG Module

resource "aws_security_group" "example" {
  for_each = var.security_group_parameters
  name     = each.value.name
  vpc_id   = each.value.vpc_id

  tags = merge(each.value.tags, { Name : each.key })
  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags] # Ignore changes to tags to avoid unnecessary updates
  }
}

resource "aws_vpc_security_group_ingress_rule" "ipv4_ingress_example" {
  for_each          = var.ipv4_ingress_rule != {} ? var.ipv4_ingress_rule : {}
  security_group_id = each.value.security_group_id
  cidr_ipv4         = each.value.cidr_ipv4  # VPC CIDR
  from_port         = each.value.from_port
  ip_protocol       = each.value.protocol
  to_port           = each.value.to_port
}

resource "aws_vpc_security_group_ingress_rule" "ipv6_ingress_example" {
  for_each          = var.ipv6_ingress_rule != {} ? var.ipv6_ingress_rule : {}
  security_group_id = each.value.security_group_id
  cidr_ipv6         = each.value.cidr_ipv6
  from_port         = each.value.from_port
  ip_protocol       = each.value.protocol
  to_port           = each.value.to_port
}

resource "aws_vpc_security_group_egress_rule" "ipv4_egress_example" {
  for_each          = var.ipv4_egress_rule != {} ? var.ipv4_egress_rule : {}
  security_group_id = each.value.security_group_id
  cidr_ipv4         = each.value.cidr_ipv4 # "0.0.0.0/0"
  ip_protocol       = each.value.protocol  # "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "ipv6_egress_example" {
  for_each          = var.ipv6_egress_rule != {} ? var.ipv6_egress_rule : {}
  security_group_id = each.value.security_group_id
  cidr_ipv6         = each.value.cidr_ipv6 # "::/0"
  ip_protocol       = each.value.protocol  # "-1" # semantically equivalent to all ports
}