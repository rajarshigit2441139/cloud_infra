# EKS Nodegroup Child module

# data "aws_iam_policy_document" "node_assume" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "node" {
#   for_each = var.nodegroup_parameters

#   name = "${each.key}-role"

#   assume_role_policy = data.aws_iam_policy_document.node_assume.json
# }

# resource "aws_iam_role_policy_attachment" "eks_worker_node" {
#   for_each   = var.nodegroup_parameters
#   role       = aws_iam_role.node[each.key].name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }

# resource "aws_iam_role_policy_attachment" "eks_cni" {
#   for_each   = var.nodegroup_parameters
#   role       = aws_iam_role.node[each.key].name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }

# resource "aws_iam_role_policy_attachment" "ecr_read" {
#   for_each = var.enable_ecr_access ? var.nodegroup_parameters : {}

#   role       = aws_iam_role.node[each.key].name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# # CUSTOM POLICY ADDITION EXMPLE
# # IF tettaform.tfvars is
# #   additional_policies = {
# #    s3 = {
# #      nodegroups = ["app-ng", "worker-ng"]
# #      policy     = ["JSON1", "JSON2"]
# #      }

# #    cloudwatch = {
# #      nodegroups = ["logs-ng"]
# #      policy     = ["JSON3"]
# #      }
# #   }


# locals {
#   custom_policy_list = flatten([
#     for pol_name, pol in var.additional_policies : [
#       for idx, json in pol.policy : {
#         pol_name = pol_name
#         idx      = idx
#         json     = json
#       }
#     ]
#   ])
# }

# # OUTPUT:
# # [
# #   { pol_name="s3", idx=0, json="JSON1" },
# #   { pol_name="s3", idx=1, json="JSON2" },
# #   { pol_name="cloudwatch", idx=0, json="JSON3" }
# # ]

# resource "aws_iam_policy" "custom" {
#   for_each = {
#     for item in local.custom_policy_list :
#     "${item.pol_name}-${item.idx}" => item
#   }

#   name   = "${each.value.pol_name}-${each.value.idx}"
#   policy = each.value.json
# }

# # OUTPUT:
# # {
# #   "s3-0"         = { pol_name="s3", idx=0, json="JSON1" }
# #   "s3-1"         = { pol_name="s3", idx=1, json="JSON2" }
# #   "cloudwatch-0" = { pol_name="cloudwatch", idx=0, json="JSON3" }
# # }

# locals {
#   # Build a list of attachments where each attachment references the actual created policy key
#   custom_policy_attachments = flatten([
#     for pol_name, pol in var.additional_policies : [
#       for ng_name in pol.nodegroups : [
#         for idx, json in pol.policy : {
#           key       = "${ng_name}-${pol_name}-${idx}" # unique map key for the attachment
#           nodegroup = ng_name
#           policy    = "${pol_name}-${idx}" # matches aws_iam_policy.custom key (eg "s3-0")
#         }
#       ]
#     ]
#   ])
# }

# # OUTPUT:
# # [
# #   { key="app-ng-s3-0", nodegroup="app-ng", policy="s3-0" },
# #   { key="app-ng-s3-1", nodegroup="app-ng", policy="s3-1" },
# #   { key="log-ng-cloudwatch-0", nodegroup="log-ng", policy="cloudwatch-0" }
# # ]



# resource "aws_iam_role_policy_attachment" "custom" {
#   for_each = {
#     for item in local.custom_policy_attachments :
#     item.key => item
#   }

#   role       = aws_iam_role.node[each.value.nodegroup].name
#   policy_arn = aws_iam_policy.custom[each.value.policy].arn
# }

# # OUTPUT:
# # aws_iam_role.node["app-ng"].name
# #   = "app-ng-role"
# # aws_iam_policy.custom["s3-0"].arn
# #   = <ARN for policy s3-0>
# # ... like this





# resource "aws_eks_node_group" "nodegroup" {
#   for_each = var.nodegroup_parameters

#   cluster_name    = var.cluster_name
#   node_group_name = each.key
#   node_role_arn   = aws_iam_role.node[each.key].arn
#   subnet_ids      = each.value.subnet_ids

#   scaling_config {
#     min_size     = each.value.min_size
#     max_size     = each.value.max_size
#     desired_size = each.value.desired_size
#   }

#   instance_types = each.value.instance_types

#   tags = merge(each.value.tags, {
#     Name : each.key
#   })



#   lifecycle {
#     prevent_destroy = false
#     ignore_changes  = [tags] # Ignore changes to tags to avoid unnecessary updates
#   }
#   depends_on = [
#     aws_iam_role.node,
#     aws_iam_role_policy_attachment.eks_worker_node,
#     aws_iam_role_policy_attachment.eks_cni,
#     aws_iam_role_policy_attachment.ecr_read,
#     aws_iam_role_policy_attachment.custom,
#     # OPTIONAL but recommended:
#     # module.security_group
#     # module.security_group_rules
#   ]

# }


data "aws_iam_policy_document" "node_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node" {
  for_each = var.nodegroup_parameters

  name               = "${each.key}-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  for_each   = var.nodegroup_parameters
  role       = aws_iam_role.node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  for_each   = var.nodegroup_parameters
  role       = aws_iam_role.node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  for_each = var.enable_ecr_access ? var.nodegroup_parameters : {}

  role       = aws_iam_role.node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

locals {
  custom_policy_list = flatten([
    for pol_name, pol in var.additional_policies : [
      for idx, json in pol.policy : {
        pol_name = pol_name
        idx      = idx
        json     = json
      }
    ]
  ])
}

resource "aws_iam_policy" "custom" {
  for_each = {
    for item in local.custom_policy_list :
    "${item.pol_name}-${item.idx}" => item
  }

  name   = "${each.value.pol_name}-${each.value.idx}"
  policy = each.value.json
}

locals {
  custom_policy_attachments = flatten([
    for pol_name, pol in var.additional_policies : [
      for ng_name in pol.nodegroups : [
        for idx, json in pol.policy : {
          key       = "${ng_name}-${pol_name}-${idx}"
          nodegroup = ng_name
          policy    = "${pol_name}-${idx}"
        }
      ]
    ]
  ])
}

resource "aws_iam_role_policy_attachment" "custom" {
  for_each = {
    for item in local.custom_policy_attachments :
    item.key => item
  }

  role       = aws_iam_role.node[each.value.nodegroup].name
  policy_arn = aws_iam_policy.custom[each.value.policy].arn
}


# Create LT per nodegroup with YOUR SG
resource "aws_launch_template" "ng_lt" {
  for_each = var.nodegroup_parameters

  name_prefix            = "${each.key}-lt"
  image_id               = each.value.instance_ami
  instance_type          = each.value.instance_types
  vpc_security_group_ids = each.value.node_security_group_ids # << YOUR SG PASSED FROM ROOT

  tag_specifications {
    resource_type = "instance"

    tags = merge(each.value.tags, {
      Name = "${each.key}-node"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(each.value.tags, {
      Name = "${each.key}-volume"
    })
  }
}

# ----------------------------------------------------------
# ADDING CUSTOM SECURITY GROUP TO NODEGROUP
# ----------------------------------------------------------

resource "aws_eks_node_group" "nodegroup" {
  for_each = var.nodegroup_parameters

  cluster_name    = var.cluster_name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node[each.key].arn
  subnet_ids      = each.value.subnet_ids

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  tags = merge(each.value.tags, {
    Name : each.key
  })

  launch_template {
    id      = aws_launch_template.ng_lt[each.key].id
    version = "$Latest"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }

  depends_on = [
    aws_iam_role.node,
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.ecr_read,
    aws_iam_role_policy_attachment.custom,
    aws_launch_template.ng_lt
  ]
}

