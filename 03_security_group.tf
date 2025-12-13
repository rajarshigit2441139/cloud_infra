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
# locals {
#   generated_ipv4_ingress_parameters = {
#     for workspace, ings in var.ipv4_ingress_rule :
#     workspace => {
#       for name, ing in ings :
#       name => merge(
#         ing,
#         { cidr_ipv4         = local.vpc_cidr_by_name[ing.vpc_name]
#           security_group_id = local.sgs_id_by_name[ing.sg_name]
#         }
#       )
#     }
#   }
# }

locals {
  generated_ipv4_ingress_parameters = {
    for workspace, ings in var.ipv4_ingress_rule :
    workspace => {
      for name, ing in ings :
      name => merge(
        ing,
        {
          cidr_ipv4                    = try(local.vpc_cidr_by_name[ing.vpc_name], null)
          security_group_id            = local.sgs_id_by_name[ing.sg_name]
          referenced_security_group_id = try(local.sgs_id_by_name[ing.source_security_group_name], null)
        }
      )
    }
  }
}



# IPv4 Egress
# locals {
#   generated_ipv4_egress_parameters = {
#     for workspace, egrs in var.ipv4_egress_rule :
#     workspace => {
#       for name, egr in egrs :
#       name => merge(
#         egr,
#         { security_group_id = local.sgs_id_by_name[egr.sg_name] }
#       )
#     }
#   }
# }

locals {
  generated_ipv4_egress_parameters = {
    for workspace, egrs in var.ipv4_egress_rule :
    workspace => {
      for name, egr in egrs :
      name => merge(
        egr,
        {
          security_group_id            = local.sgs_id_by_name[egr.sg_name]
          cidr_ipv4                    = try(local.vpc_cidr_by_name[egr.vpc_name], null)
          referenced_security_group_id = try(local.sgs_id_by_name[egr.source_security_group_name], null)
        }
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