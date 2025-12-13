module "chat_app_eip" {
  source         = "./modules/aws/eip"
  eip_parameters = lookup(var.eip_parameters, terraform.workspace)
}