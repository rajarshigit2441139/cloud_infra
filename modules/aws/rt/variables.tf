variable "rt_parameters" {
  description = "Route table parameters"
  type = map(object({
    vpc_name = string
    vpc_id   = optional(string)
    tags     = optional(map(string), {})
    routes = optional(list(object({
      cidr_block = string
      use_igw    = optional(bool, true)
      gateway_id = string
    })), [])
  }))
  default = {}
}

variable "internet_gateway_ids" {
  description = "Map of internet gateway IDs keyed by identifier"
  type        = map(string)
  default     = {}
}
