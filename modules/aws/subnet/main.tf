resource "aws_subnet" "example" {
  for_each   = var.subnet_parameters
  vpc_id     = each.value.vpc_id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags = merge(each.value.tags, {
    Name : each.key
  })
  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags] # Ignore changes to tags to avoid unnecessary updates
  }
}