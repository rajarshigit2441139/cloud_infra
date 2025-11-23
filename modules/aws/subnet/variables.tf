variable "subnet_parameters" {
  description = "Subnet parameters"
  type = map(object({
    cidr_block = string
    vpc_name   = string
    vpc_id     = string
    availability_zone = string
    az_index   = number
    tags       = optional(map(string), {})
  }))
  default = {}
}