# VPC CIDR BLOCK
variable "ssmk_vpc_cidr" {
  default = "10.0.0.0/16"
}

# Public Subnet 1
variable "aws_pubsn1_cidr" {
  default = "10.0.0.0/24"
}

# Public Subnet 2
variable "aws_pubsn2_cidr" {
  default = "10.0.1.0/24"
}

# Private Subnet 1
variable "aws_prvsn1_cidr" {
  default = "10.0.2.0/24"
}

# Private Subnet 2
variable "aws_prvsn2_cidr" {
  default = "10.0.3.0/24"
}

# Private Subnet 3
variable "aws_prvsn3_cidr" {
  default = "10.0.4.0/24"
}

#Availability Zone 1
variable "az_1" {
  default = "eu-west-2a"
}

#Availability Zone 2
variable "az_2" {
  default = "eu-west-2b"
}

#Availability Zone 3
variable "az_3" {
  default = "eu-west-2c"
}

#All IP CIDR
variable "all" {
  default = "0.0.0.0/0"
}

#Any Ports
variable "any" {
  default = "0"
}

# Bastion Host AMI 
variable "ami_ubuntu" {
    default = "ami-0f540e9f488cfa27d" 
}
#  Bastion Host Instance Type
variable "aws_instance_type" {
    default = "t2.micro"
}

#t2 medium instance type
variable "instance_type" {
    default = "t2.medium"
}

variable "lb_name" {
    default = "loadbalancer_node"
}

/* variable "cluster_init_yml" {
  default     = "~/kubernetes/cluster-yml"
  description = "this is path to the cluster.yml file"
}

variable "deployment_yml" {
  default     = "~/kubernetes/deployment_yml"
  description = "this is path to the deployment.yml file"
}

variable "join_cluster_yml" {
  default     = "~/kubernetes/join_yml"
  description = "this is path to the join.yml file"
}

variable "installation_yml" {
  default     = "~/kubernetes/installation_yml"
  description = "this is path to the installation.yml file"
}
variable "monitoring_yml" {
  default     = "~/kubernetes/monitoring_yml"
  description = "this is path to the monitoring_yml file"
} */