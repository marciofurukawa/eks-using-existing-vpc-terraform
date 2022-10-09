#==============================================================
#                General Variables
#==============================================================
aws_region = "us-east-1"

project     = "poc-private-terraform"
environment = "prd"

tags = {
  "project"     = "eks-private-project"
  "versioning"  = "terraform"
  "environment" = "prd"
}

#=================================================================
#                          EKS Variables
#=================================================================

cluster_version = "1.23"

# map_users = [{
#     "userarn"  = "arn:aws:iam::562415927517:user/gitlab.user"
#     "username" = "gitlab.user"
#     "groups"   = ["system:masters"]
# }]

instance_type = "m6i.xlarge"

#===================================================================
#                        VPC variables
#==================================================================

private_subnets_vpc = ["subnet-01", "subnet-02", "subnet-03", "subnet-04"]
vpc                 = "vpc-00"
