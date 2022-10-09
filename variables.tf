#============================================================
#             General variables
#============================================================

variable "project" {
  description = "Project name."
  type        = string
}

variable "environment" {
  description = "Environment name (for instance: PRD for Production)."
  type        = string
}

variable "tags" {
  description = "List of tags (key and value) for the resources in the Cloud Provider."
  type        = map(string)
}

variable "aws_region" {
  description = "AWS region name where the resources will be created."
  type        = string
}

locals {
  description  = "EKS Cluster name."
  cluster_name = "eks-${var.environment}-${var.project}"
}

#============================================================
#             VPC variables
#============================================================

variable "vpc" {
  description = "VPC name (pre-existing resource)."
  type        = string
}

variable "private_subnets_vpc" {
  description = "List of private subnets that already exists in the VPC (pre-existing resource)."
  type        = list(string)
}

#============================================================
#             EKS variables
#============================================================

variable "cluster_version" {
  description = "EKS Cluster version."
  type        = string
}

variable "disk_size" {
  description = "EKS instance disk size."
  type        = number
}

variable "instance_type" {
  description = "EKS Cluster instance type."
  type        = string
}

variable "ngroup_min_size" {
  description = "Minimal size of node groups instances."
  type        = number
}

variable "ngroup_max_size" {
  description = "Maximum size of node groups instances."
  type        = number
}

variable "ngroup_desired_size" {
  description = "Desired size of node groups instances."
  type        = number
}

variable "ngroup_capacity_type" {
  description = "Type of capacity of node groups instances."
  type        = string
}
