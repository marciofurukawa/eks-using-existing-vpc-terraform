#==============================================================
#                          General Variables
#==============================================================
aws_region = "us-east-1" ## put your AWS Region here

project     = "poc-private-terraform" ## put project-name here
environment = "prd"                   ## put your environment here

tags = {
  "project"     = "eks-private-project"
  "versioning"  = "terraform"
  "environment" = "prd"
} ## put your tags here

#=================================================================
#                          EKS Variables
#=================================================================

cluster_version = "1.23" ## put your EKS Cluster version here

disk_size     = 50           ## put your EKS disk size here
instance_type = "m6i.xlarge" ## put your instance type here

ngroup_min_size      = 3           ## put your node group minimum size here
ngroup_max_size      = 5           ## put your node group maximum size here
ngroup_desired_size  = 3           ## put your node group desired size here
ngroup_capacity_type = "ON_DEMAND" ## put your node group capacity type here

#===================================================================
#                          VPC variables
#==================================================================

private_subnets_vpc = ["subnet-01", "subnet-02", "subnet-03", "subnet-04"] ## put your private subnets IDs here
vpc                 = "vpc-00"                                             ## put your VPC ID here
