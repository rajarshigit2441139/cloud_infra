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
  nat_gateway_ids      = local.extract_nat_gateway_ids

  depends_on = [module.chat_app_vpc, module.chat_app_ig, module.chat_app_nat]
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


