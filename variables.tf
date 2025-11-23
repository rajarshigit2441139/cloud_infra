# -------------- VPC Parameters -------------- #

variable "vpc_parameters" {
  description = "VPC parameters"
  type = map(map(object({
    cidr_block           = string
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, true)
    tags                 = optional(map(string), {})
  })))
  default = {}
}


# -------------- Subnet Parameters -------------- #

variable "subnet_parameters" {
  description = "Subnet parameters"
  type = map(map(object({
    cidr_block = string
    vpc_name   = string
    vpc_id     = optional(string)
    availability_zone = optional(string)
    az_index = number
    tags       = optional(map(string), {})
  })))
  default = {}
}


# -------------- IGW Parameters -------------- #

variable "igw_parameters" {
  description = "IGW parameters"
  type = map(map(object({
    vpc_name = string
    # vpc_id   = optional(string)
    tags     = optional(map(string), {})
  })))
  default = {}
}


# -------------- NAT Parameters -------------- #

variable "nat_gateway_parameters" {
  description = "Nat parameters"
  type = map(object({
    subnet_id                          = string
    connectivity_type                  = optional(string) #"private"
    secondary_private_ip_address_count = optional(number)
    allocation_id                      = optional(string)
    secondary_allocation_ids           = optional(list(string))
    secondary_private_ip_addresses     = optional(list(string))
    tags                               = optional(map(string), {})
  }))
  default = {}
}


# -------------- RT Parameters -------------- #

variable "rt_parameters" {
  description = "Route table parameters"
  type = map(map(object({
    vpc_name = string
    vpc_id   = optional(string)
    tags     = optional(map(string), {})
    routes = optional(list(object({
      cidr_block = string
      use_igw    = optional(bool, true)
      gateway_id = optional(string)
    })), [])
  })))
  default = {}
}
variable "internet_gateway_ids" {
  description = "Map of internet gateway IDs keyed by identifier"
  type        = map(string)
  default     = {}
}


# -------------- RT Associations Parameters -------------- #

variable "rt_association_parameters" {
  description = "RT association parameters"
  type = map(object({
    subnet_name    = string
    subnet_id      = optional(string)
    route_table_id = optional(string)
    rt_name        = string
  }))
  default = {}
}


# -------------- SG Parameters -------------- #

variable "security_group_parameters" {
  description = "AWS Security Group parameters"
  type = map(map(object({
    name     = string
    vpc_name = string
    vpc_id   = optional(string)
    tags     = optional(map(string), {})
  })))
  default = {}
}


# -------------- SG Rules Parameters -------------- #

variable "ipv4_ingress_rule" {
  description = "IPv4 ingress rule parameters"
  type = map(map(object({
    vpc_name          = string
    sg_name           = string
    security_group_id = optional(string)
    from_port         = number
    to_port           = number
    protocol          = string
    cidr_ipv4         = optional(string) #VPC CIDR blocks can be passed here
  })))
  default = {}
}

variable "ipv4_egress_rule" {
  description = "IPv4 engress rule parameters"
  type = map(map(object({
    vpc_name          = string
    sg_name           = string
    security_group_id = optional(string)
    cidr_ipv4         = optional(string) #VPC CIDR blocks can be passed here or IPs: "0.0.0.0"
    protocol          = string    
  })))
  default = {}
}
