# -------------- Local Extract ------------------#

# Extract VPC IDs
locals {
  vpc_id_by_name = { for name, vpc in module.chat_app_vpc.vpcs : name => vpc.id }
}

# Extract VPC cidr
locals {
  vpc_cidr_by_name = { for name, vpc in module.chat_app_vpc.vpcs : name => vpc.cidr_block }
}

# Extract sg_id
locals {
  sgs_id_by_name = { for name, sg in module.chat_app_security_group.sgs : name => sg.id }
}

# Extract Subnet IDs for RT associations
locals {
  subnet_id_by_name = { for name, subnet in module.chat_app_subnet.subnets : name => subnet.id }
}

# Extract RT IDs for RT associations
locals {
  rt_id_by_name = module.chat_app_rt.route_table_ids
}

# Extract Internet Gateway IDs
locals {
  extract_internet_gateway_ids = {
    for name, igw_obj in module.chat_app_ig.igws :
    name => igw_obj.id
  }
}


# -------------- VPC module -------------- #
module "chat_app_vpc" {
  source         = "./modules/aws/vpc"
  vpc_parameters = lookup(var.vpc_parameters, terraform.workspace)
}


# -------------- Subnet module -------------- #

# AZ
data "aws_availability_zones" "available" {}

# Inject VPC IDs for subnets
locals {
  generated_subnet_parameters = {
    for workspace, subnets in var.subnet_parameters :
    workspace => {
      for name, subnet in subnets :
      name => merge(
        subnet,
        { vpc_id            = local.vpc_id_by_name[subnet.vpc_name]
          availability_zone = data.aws_availability_zones.available.names[subnet.az_index]
        }
      )
    }
  }
}

module "chat_app_subnet" {
  source            = "./modules/aws/subnet"
  subnet_parameters = lookup(local.generated_subnet_parameters, terraform.workspace)
  depends_on        = [module.chat_app_vpc]
}


# -------------- IGW module -------------- #

# Inject VPC IDs for IGWs
locals {
  generated_igw_parameters = {
    for workspace, igws in var.igw_parameters :
    workspace => {
      for name, igw in igws :
      name => merge(
        igw,
        { vpc_id = local.vpc_id_by_name[igw.vpc_name] }
      )
    }
  }
}

module "chat_app_ig" {
  source         = "./modules/aws/igw"
  igw_parameters = lookup(local.generated_igw_parameters, terraform.workspace)
  depends_on     = [module.chat_app_vpc]
}


# -------------- RT module -------------- #

# Inject VPC IDs into rt_parameters
locals {
  generated_rt_parameters = {
    for workspace, rts in var.rt_parameters :
    workspace => {
      for name, rt in rts :
      name => merge(
        rt,
        { vpc_id = local.vpc_id_by_name[rt.vpc_name] }
      )
    }
  }
}

module "chat_app_rt" {
  source               = "./modules/aws/rt"
  rt_parameters        = lookup(local.generated_rt_parameters, terraform.workspace)
  internet_gateway_ids = local.extract_internet_gateway_ids

  depends_on = [module.chat_app_vpc, module.chat_app_ig]
}


# -------------- RT associations -------------- #

# Inject Subnet IDs and RT IDs into rt_association_parameters
locals {
  generated_rt_association_parameters = {
    for name, item in var.rt_association_parameters :
    name => merge(
      item,
      {
        subnet_id      = local.subnet_id_by_name[item.subnet_name]
        route_table_id = local.rt_id_by_name[item.rt_name]
      }
    )
  }
  depends_on = [module.chat_app_subnet, module.chat_app_rt]
}

resource "aws_route_table_association" "chat_app_rt_association" {
  for_each       = local.generated_rt_association_parameters
  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
  depends_on     = [module.chat_app_subnet, module.chat_app_rt]
}


# -------------- Security Group Module -------------- #

# Inject VPC IDs for SG
locals {
  generated_sg_parameters = {
    for workspace, sgs in var.security_group_parameters :
    workspace => {
      for name, sg in sgs :
      name => merge(
        sg,
        { vpc_id = local.vpc_id_by_name[sg.vpc_name] }
      )
    }
  }
}

# Inject vpc_cidr & sgs_id into rules parameter
#IPv4 Ingress
locals {
  generated_ipv4_ingress_parameters = {
    for workspace, ings in var.ipv4_ingress_rule :
    workspace => {
      for name, ing in ings :
      name => merge(
        ing,
        { cidr_ipv4         = local.vpc_cidr_by_name[ing.vpc_name]
          security_group_id = local.sgs_id_by_name[ing.sg_name]
        }
      )
    }
  }
}

# IPv4 Egress
locals {
  generated_ipv4_egress_parameters = {
    for workspace, egrs in var.ipv4_egress_rule :
    workspace => {
      for name, egr in egrs :
      name => merge(
        egr,
        { security_group_id = local.sgs_id_by_name[egr.sg_name] }
      )
    }
  }
}


module "chat_app_security_group" {
  source                    = "./modules/aws/security_group"
  security_group_parameters = lookup(local.generated_sg_parameters, terraform.workspace)
  depends_on                = [module.chat_app_vpc]
}

module "chat_app_security_rules" {
  source            = "./modules/aws/security_group"
  ipv4_ingress_rule = lookup(local.generated_ipv4_ingress_parameters, terraform.workspace)
  ipv4_egress_rule  = lookup(local.generated_ipv4_egress_parameters, terraform.workspace)
  depends_on        = [module.chat_app_security_group]
}