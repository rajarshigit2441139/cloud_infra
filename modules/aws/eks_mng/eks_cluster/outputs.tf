output "eks_clusters" {
  description = "All EKS clusters created by this module"
  value = {
    for k, v in aws_eks_cluster.cluster :
    k => {
      cluster_name     = v.name
      cluster_arn      = v.arn
      cluster_endpoint = v.endpoint
      cluster_cert     = v.certificate_authority[0].data
      # cluster_sg_id    = aws_security_group.cluster_sg[k].id
      cluster_role_arn = aws_iam_role.eks_cluster[k].arn
      cluster_version  = v.version
    }
  }
}
