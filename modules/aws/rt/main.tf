resource "aws_route_table" "example" {
  for_each = var.rt_parameters
  vpc_id   = each.value.vpc_id
  tags     = merge(each.value.tags, { Name : each.key })
  dynamic "route" {
    for_each = each.value.routes
    content {
      cidr_block = route.value.cidr_block
      gateway_id = route.value.use_igw ? var.internet_gateway_ids[route.value.gateway_id] : route.value.gateway_id
    }
  }
  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags] # Ignore changes to tags to avoid unnecessary updates
  }
}
