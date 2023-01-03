
# Create KeyPair 
resource "tls_private_key" "ssmk_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssmk_prv" {
  content  = tls_private_key.ssmk_key.private_key_pem
  filename = "ssmk_key"
  provisioner "local-exec" {
    command = "chmod 400 ssmk_key"
  }
}

resource "aws_key_pair" "ssmk_pubkey" {
  key_name   = "ssmk_pub_key"
  public_key = tls_private_key.ssmk_key.public_key_openssh
}


# Create VPC
resource "aws_vpc" "ssmk_vpc" {
  cidr_block = var.ssmk_vpc_cidr
  tags = {
    Name = "ssmk_vpc"
  }
}

# Create VPC Public Subnet 1
resource "aws_subnet" "ssmk_pub_sn1" {
  vpc_id            = aws_vpc.ssmk_vpc.id
  cidr_block        = var.aws_pubsn1_cidr
  availability_zone = var.az_1
  tags = {
    Name = "ssmk_pub_sn1"
  }
}

# Create VPC Public Subnet 2
resource "aws_subnet" "ssmk_pub_sn2" {
  vpc_id            = aws_vpc.ssmk_vpc.id
  cidr_block        = var.aws_pubsn2_cidr
  availability_zone = var.az_2
  tags = {
    Name = "ssmk_pub_sn2"
  }
}

# Create VPC Private Subnet 1
resource "aws_subnet" "ssmk_prv_sn1" {
  vpc_id            = aws_vpc.ssmk_vpc.id
  cidr_block        = var.aws_prvsn1_cidr
  availability_zone = var.az_1
  tags = {
    Name = "ssmk_prv_sn1"
  }
}

# Create VPC Private Subnet 2
resource "aws_subnet" "ssmk_prv_sn2" {
  vpc_id            = aws_vpc.ssmk_vpc.id
  cidr_block        = var.aws_prvsn2_cidr
  availability_zone = var.az_2
  tags = {
    Name = "ssmk_prv_sn2"
  }
}

# Create VPC Private Subnet 3
resource "aws_subnet" "ssmk_prv_sn3" {
  vpc_id            = aws_vpc.ssmk_vpc.id
  cidr_block        = var.aws_prvsn3_cidr
  availability_zone = var.az_3
  tags = {
    Name = "ssmk_prv_sn3"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "ssmk_igw" {
  vpc_id = aws_vpc.ssmk_vpc.id
  tags = {
    Name = "ssmk_igw"
  }
}

# Create Public Route Table
resource "aws_route_table" "ssmk_rt" {
  vpc_id = aws_vpc.ssmk_vpc.id

  route {
    cidr_block = var.all
    gateway_id = aws_internet_gateway.ssmk_igw.id
  }
}

# Create Route Table Association Public Subnet 1
resource "aws_route_table_association" "ssmk_rt_ass_pub_sn1" {
  subnet_id      = aws_subnet.ssmk_pub_sn1.id
  route_table_id = aws_route_table.ssmk_rt.id
}
# Create Route Table Association Public Subnet 2
resource "aws_route_table_association" "ssmk_rt_ass_pub_sn2" {
  subnet_id      = aws_subnet.ssmk_pub_sn2.id
  route_table_id = aws_route_table.ssmk_rt.id
}

# Create Elastic IP for NAT gateway
resource "aws_eip" "ssmk_nat_eip" {
  vpc = true
  tags = {
    Name = "ssmk_nat_eip"
  }
}

# Create NAT gateway
resource "aws_nat_gateway" "ssmk_ngw" {
  allocation_id = aws_eip.ssmk_nat_eip.id
  subnet_id     = aws_subnet.ssmk_pub_sn1.id

  tags = {
    Name = "ssmk_ngw"
  }

  depends_on = [aws_internet_gateway.ssmk_igw]
}

# Create security Group
resource "aws_security_group" "ssmk_sg_master_node" {
  name        = "ssmk_sg_master_node"
  description = "Allow outbound traffic"
  vpc_id      = aws_vpc.ssmk_vpc.id
  ingress {
    description = "SSH"
    from_port   = var.any
    to_port     = var.any
    protocol    = "-1"
    cidr_blocks = [var.all]
  }

  egress {
    description = "HTTP"
    from_port   = var.any
    to_port     = var.any
    protocol    = "-1"
    cidr_blocks = [var.all]
  }
  tags = {
    Name = "ssmk_sg_master_node"
  }
}

# Security group for Bastion Host
resource "aws_security_group" "ssmk_sg_bastion" {
  name        = "ssmk_sg_bastion"
  description = "Allow traffic for ssh"
  vpc_id      = aws_vpc.ssmk_vpc.id

  ingress {
    description = "Allow ssh traffic"
    from_port   = var.any
    to_port     = var.any
    protocol    = "tcp"
    cidr_blocks = [var.all]
  }

  egress {
    from_port   = var.any
    to_port     = var.any
    protocol    = "-1"
    cidr_blocks = [var.all]
  }

  tags = {
    Name = "ssmk_sg_bastion"
  }
}
# Provisioning Bastion Host
resource "aws_instance" "Bastion_Host_ssmk" {
  ami                         = var.ami_ubuntu
  instance_type               = var.aws_instance_type
  key_name                    = aws_key_pair.ssmk_pubkey.key_name
  subnet_id                   = aws_subnet.ssmk_pub_sn1.id
  vpc_security_group_ids      = [aws_security_group.ssmk_sg_bastion.id]
  associate_public_ip_address = true
  user_data                   = <<-EOF
#!/bin/bash
echo "${tls_private_key.ssmk_key.private_key_pem}" > /home/ubuntu/ssmk_key
chmod 400 ssmk_key
sudo hostnamectl set-hostname Bastion
EOF 

  tags = {
    Name = "Bastion_Host_ssmk"
  }
}

# Create HAProxy Load Balancer
resource "aws_instance" "loadbalancer" {
  ami                         = var.ami_ubuntu
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.ssmk_sg_master_node.id]
  subnet_id                   = aws_subnet.ssmk_pub_sn1.id
  key_name                    = aws_key_pair.ssmk_pubkey.key_name
  associate_public_ip_address = true
  /* user_data = local.haproxy_user_data */
  tags = {
    Name = var.lb_name
  }
} #Create Master node1
resource "aws_instance" "Master01_node" {
  ami                         = var.ami_ubuntu
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.ssmk_prv_sn1.id
  vpc_security_group_ids      = [aws_security_group.ssmk_sg_master_node.id]
  key_name                    = aws_key_pair.ssmk_pubkey.key_name
  associate_public_ip_address = false
   user_data = <<-EOF
#!/bin/bash
sudo su
apt-get update -y
apt-get upgrade -y
systemctl reload sshd
chmod -R 700 .ssh/
chown ubuntu /home/ubuntu/.ssh/authoried_keys
chgrp ubuntu /home/ubuntu/.ssh/authoried_keys
sudo hostnamectl set-hostname Master01
EOF

  tags = {
      Name = "Master01_node"
  }
}
/* #Data Output for Master-node01
data "aws_instance" "Master01_IP_address" {
  filter {
    name   = "tag:Name"
    values = ["Master01_node"]
  }
  depends_on = [
    aws_instance.Master01_node
  ]
} */

#Create Master node
resource "aws_instance" "Master02_node" {
  ami                         = var.ami_ubuntu
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.ssmk_prv_sn2.id
  vpc_security_group_ids      = [aws_security_group.ssmk_sg_master_node.id]
  key_name                    = aws_key_pair.ssmk_pubkey.key_name
  associate_public_ip_address = false
   user_data = <<-EOF
#!/bin/bash
sudo su
apt-get update -y
apt-get upgrade -y
systemctl reload sshd
chmod -R 700 .ssh/
chown ubuntu /home/ubuntu/.ssh/authoried_keys
chgrp ubuntu /home/ubuntu/.ssh/authoried_keys
sudo hostnamectl set-hostname Master02
EOF

  tags = {
      Name = "Master02_node"
  }
}
/* #Data Output for Master-node02
data "aws_instance" "Master02_IP_address" {
  filter {
    name   = "tag:Name"
    values = ["Master02_node"]
  }
  depends_on = [
    aws_instance.Master02_node
  ]
} */
#Create Master node3
resource "aws_instance" "Master03_node" {
  ami                         = var.ami_ubuntu
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.ssmk_prv_sn3.id
  vpc_security_group_ids      = [aws_security_group.ssmk_sg_master_node.id]
  key_name                    = aws_key_pair.ssmk_pubkey.key_name
  associate_public_ip_address = false
   user_data = <<-EOF
#!/bin/bash
sudo su
apt-get update -y
apt-get upgrade -y
systemctl reload sshd
chmod -R 700 .ssh/
chown ubuntu /home/ubuntu/.ssh/authoried_keys
chgrp ubuntu /home/ubuntu/.ssh/authoried_keys
sudo hostnamectl set-hostname Master03
EOF

  tags = {
      Name = "Master03_node"
  }
}
/* #Data Output for Master-node03
data "aws_instance" "Master03_IP_address" {
  filter {
    name   = "tag:Name"
    values = ["Master03_server"]
  }
  depends_on = [
    aws_instance.Master03_node
  ]
} */


#Create Worker Node 1
resource "aws_instance" "Worker01_node" {
  ami                         = var.ami_ubuntu
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.ssmk_prv_sn1.id
  vpc_security_group_ids      = [aws_security_group.ssmk_sg_master_node.id]
  key_name                    = aws_key_pair.ssmk_pubkey.key_name
  associate_public_ip_address = false
   user_data = <<-EOF
#!/bin/bash
sudo su
apt-get update -y
apt-get upgrade -y
systemctl reload sshd
chmod -R 700 .ssh/
chown ubuntu /home/ubuntu/.ssh/authoried_keys
chgrp ubuntu /home/ubuntu/.ssh/authoried_keys
sudo hostnamectl set-hostname Worker01
EOF

  tags = {
      Name = "Worker01_node"
  }
}

/* #Data Output for Worker_node01
data "aws_instance" "Worker01_IP_address" {
  filter {
    name   = "tag:Name"
    values = ["Worker01_server"]
  }
  depends_on = [
    aws_instance.Worker01_node
  ]
} */

#Create Worker Node 2
resource "aws_instance" "Worker02_node" {
  ami                         = var.ami_ubuntu
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.ssmk_prv_sn2.id
  vpc_security_group_ids      = [aws_security_group.ssmk_sg_master_node.id]
  key_name                    = aws_key_pair.ssmk_pubkey.key_name
  associate_public_ip_address = false
   user_data = <<-EOF
#!/bin/bash
sudo su
apt-get update -y
apt-get upgrade -y
systemctl reload sshd
chmod -R 700 .ssh/
chown ubuntu /home/ubuntu/.ssh/authoried_keys
chgrp ubuntu /home/ubuntu/.ssh/authoried_keys
sudo hostnamectl set-hostname Worker02
EOF

  tags = {
      Name = "Worker02_node"
  }
}

/* #Data Output for Worker_node02
data "aws_instance" "Worker02_IP_address" {
  filter {
    name   = "tag:Name"
    values = ["Worker02_server"]
  }
  depends_on = [
    aws_instance.Worker02_node
  ]
} */


/* # Provision Ansible Host
resource "aws_instance" "Ansible_Node" {
ami                         = var.ami_ubuntu
instance_type               = var.instance_type
key_name                    = aws_key_pair.ssmk_pubkey.key_name
subnet_id                   = aws_subnet.ssmk_prv_sn1.id
vpc_security_group_ids      = [aws_security_group.ssmk_sg_master_node.id]
associate_public_ip_address = false
availability_zone           = var.az_1
 user_data = <<-EOF
!/bin/bash
sudo apt-get update -y
sudo apt-get install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install ansible -y
echo "pubkeyAcceptKeyTypes=+ssh-rsa" >> /etc/ssh/sshd_config.d/10-insecure-rsa-keysig.conf
systemctl reload sshd
sudo bash -c ' echo "strictHostKeyChecking No" >> /etc/ssh/ssh_config'
echo "${tls_private_key.ssmk_key.private_key_pem}" >> /home/ubuntu/.ssh/sock-key
chown ubuntu /home/ubuntu/.ssh/sock-key 
chgrp ubuntu /home/ubuntu/.ssh/sock-key 
chmod 600 /home/ubuntu/.ssh/sock-key
sudo mkdir /etc/ansible
sudo touch /etc/ansible/hosts
sudo echo "[Master]" >> /etc/ansible/hosts
sudo echo "${data.aws_instance.Master01_IP_address.private_ip} ansible_ssh_private_key_file=/home/ubuntu/.ssh/sock-key" >> /etc/ansible/hosts
sudo echo "[Masters]" >> /etc/ansible/hosts
sudo echo "${data.aws_instance.Master02_IP_address.private_ip} ansible_ssh_private_key_file=/home/ubuntu/.ssh/sock-key" >> /etc/ansible/hosts
sudo echo "${data.aws_instance.Master03_IP_address.private_ip} ansible_ssh_private_key_file=/home/ubuntu/.ssh/sock-key" >> /etc/ansible/hosts
sudo echo "[Workers]" >> /etc/ansible/hosts
sudo echo "${data.aws_instance.Worker01_IP_address.private_ip} ansible_ssh_private_key_file=/home/ubuntu/.ssh/sock-key" >> /etc/ansible/hosts
sudo echo "${data.aws_instance.Worker02_IP_address.private_ip} ansible_ssh_private_key_file=/home/ubuntu/.ssh/sock-key" >> /etc/ansible/hosts
cd ~/etc/ansible
sudo chown -R ubuntu:ubuntu /etc/ansible
sudo touch installation.yml deployment.yml monitoring.yml cluster.yml join.yml
echo "${file(var.cluster_init_yml)}" >> /etc/ansible/cluster.yml
echo "${file(var.join_cluster_yml)}" >> /etc/ansible/join.yml
echo "${file(var.deployment_yml)}" >> /etc/ansible/deployment.yml
echo "${file(var.monitoring_yml)}" >> /etc/ansible/monitoring.yml
echo "${file(var.installation_yml)}" >> /etc/ansible/monitoring.yml
echo "[Masters]" >> /etc/ansible/hosts
echo "[Workers]" >> /etc/ansible/hosts
sudo echo "[all:vars]" >> /etc/ansible/hosts
sudo echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> /etc/ansible/hosts

sudo hostnamectl set-hostname Ansible
EOF

tags = {
    Name = "Ansible_Node"
}
} */

/* # Add an applicaction load balancer
resource "aws_lb" "ssmk-lb" {
  name                      = "ssmk-lb" 
  internal                  = false 
  load_balancer_type        = "application"
  security_groups           = [aws_security_group.ssmk_sg_master_node.id]
  subnets                   = [aws_subnet.ssmk_pub_sn1.id, aws_subnet.ssmk_pub_sn1.id]
  enable_deletion_protection = false  
  
}


# Add a load balancer listener
resource "aws_lb_listener" "ssmk-lb-listener" {
  load_balancer_arn           = aws_lb.ssmk-lb.arn
  port                        = "80"
  protocol                    = "HTTP"

  default_action {
    type               = "forward"
    target_group_arn          = aws_lb_target_group.ssmk-tg.arn
  } 
}

# Add a target group for load balancer
resource "aws_lb_target_group" "ssmk-tg" {
  name                      = "ssmk-tg"
  port                      =  30001
  protocol                  = "HTTP"
  vpc_id                    = aws_vpc.ssmk_vpc.id
  health_check {
    healthy_threshold       = 3
    unhealthy_threshold     = 5
    interval                = 30
    timeout                 = 5
    path                    = "/" 
  } 
}

# Add target group attachment for master01
resource "aws_lb_target_group_attachment" "ssmk-tg-attach-master01" {
  target_group_arn            = aws_lb_target_group.ssmk-tg.arn
  target_id                   = aws_instance.Master01_node.id
  port                        = 30001 
  
}

# Add target group attachment for master02
resource "aws_lb_target_group_attachment" "ssmk-tg-attach-master02" {
  target_group_arn            = aws_lb_target_group.ssmk-tg.arn
  target_id                   = aws_instance.Master02_node.id
  port                        = 30001 
  
}

# Add target group attachment for master03
resource "aws_lb_target_group_attachment" "ssmk-tg-attach-master03" {
  target_group_arn            = aws_lb_target_group.ssmk-tg.arn
  target_id                   = aws_instance.Master03_node.id
  port                        = 30001 
  
}

# Add target group attachment for worker01
resource "aws_lb_target_group_attachment" "ssmk-tg-attach-worker01" {
  target_group_arn            = aws_lb_target_group.ssmk-tg.arn
  target_id                   = aws_instance.Worker01_node.id
  port                        = 30001 
  
}

# Add target group attachment for worker02
resource "aws_lb_target_group_attachment" "ssmk-tg-attach-worker02" {
  target_group_arn            = aws_lb_target_group.ssmk-tg.arn
  target_id                   = aws_instance.Worker02_node.id
  port                        = 30001 
  
}

# Add Prometheus load balancer
resource "aws_lb" "prom-lb" {
  name                      = "prom-lb" 
  internal                  = false 
  load_balancer_type        = "application"
  security_groups           = [aws_security_group.ssmk_sg_master_node.id]
  subnets                   = [aws_subnet.ssmk_pub_sn1.id, aws_subnet.ssmk_pub_sn1.id]
  enable_deletion_protection = false  
  
}

# Add Prometheus load balancer listener
resource "aws_lb_listener" "prom-lb-listener" {
  load_balancer_arn           = aws_lb.prom-lb.arn
  port                        = "80"
  protocol                    = "HTTP"

  default_action {
    type               = "forward"
    target_group_arn          = aws_lb_target_group.prom-tg.arn
  } 
}

# Add Prometheus target group for load balancer
resource "aws_lb_target_group" "prom-tg" {
  name                      = "prom-tg"
  port                      =  31090
  protocol                  = "HTTP"
  vpc_id                    = aws_vpc.ssmk_vpc.id
  health_check {
    healthy_threshold       = 3
    unhealthy_threshold     = 5
    interval                = 30
    timeout                 = 5
    path                    = "/" 
  } 
}

# Add Prometheus target group attachment for master01
resource "aws_lb_target_group_attachment" "prom-tg-attach-master01" {
  target_group_arn            = aws_lb_target_group.prom-tg.arn
  target_id                   = aws_instance.Master01_node.id
  port                        = 31090
  
}

# Add Prometheus target group attachment for master02
resource "aws_lb_target_group_attachment" "prom-tg-attach-master02" {
  target_group_arn            = aws_lb_target_group.prom-tg.arn
  target_id                   = aws_instance.Master02_node.id
  port                        = 31090 
  
}

# Add Prometheus target group attachment for master03
resource "aws_lb_target_group_attachment" "prom-tg-attach-master03" {
  target_group_arn            = aws_lb_target_group.prom-tg.arn
  target_id                   = aws_instance.Master03_node.id
  port                        = 31090
  
}

# Add Prometheus target group attachment for worker01
resource "aws_lb_target_group_attachment" "prom-tg-attach-worker01" {
  target_group_arn            = aws_lb_target_group.prom-tg.arn
  target_id                   = aws_instance.Worker01_node.id
  port                        = 31090
  
}

# Add Prometheus target group attachment for worker02
resource "aws_lb_target_group_attachment" "prom-tg-attach-worker02" {
  target_group_arn            = aws_lb_target_group.prom-tg.arn
  target_id                   = aws_instance.Worker02_node.id
  port                        = 31090
  
}

# Add Grafana load balancer
resource "aws_lb" "graf-lb" {
  name                      = "graf-lb" 
  internal                  = false 
  load_balancer_type        = "application"
  security_groups           = [aws_security_group.ssmk_sg_master_node.id]
  subnets                   = [aws_subnet.ssmk_pub_sn1.id, aws_subnet.ssmk_pub_sn1.id]
  enable_deletion_protection = false  
  
}

# Add Grafana load balancer listener
resource "aws_lb_listener" "graf-lb-listener" {
  load_balancer_arn           = aws_lb.graf-lb.arn
  port                        = "80"
  protocol                    = "HTTP"

  default_action {
    type               = "forward"
    target_group_arn          = aws_lb_target_group.graf-tg.arn
  } 
}

# Add Grafana target group for load balancer
resource "aws_lb_target_group" "graf-tg" {
  name                      = "graf-tg"
  port                      =  31300
  protocol                  = "HTTP"
  vpc_id                    = aws_vpc.ssmk_vpc.id
  health_check {
    healthy_threshold       = 3
    unhealthy_threshold     = 5
    interval                = 30
    timeout                 = 5
    path                    = "/" 
  } 
}

# Add Grafana target group attachment for master01
resource "aws_lb_target_group_attachment" "graf-tg-attach-master01" {
  target_group_arn            = aws_lb_target_group.graf-tg.arn
  target_id                   = aws_instance.Master01_node.id
  port                        = 31300
  
}

# Add Grafana target group attachment for master02
resource "aws_lb_target_group_attachment" "graf-tg-attach-master02" {
  target_group_arn            = aws_lb_target_group.graf-tg.arn
  target_id                   = aws_instance.Master02_node.id
  port                        = 31300
  
}

# Add Grafana target group attachment for master03
resource "aws_lb_target_group_attachment" "graf-tg-attach-master03" {
  target_group_arn            = aws_lb_target_group.graf-tg.arn
  target_id                   = aws_instance.Master03_node.id
  port                        = 31300
  
}

# Add  Grafana target group attachment for worker01
resource "aws_lb_target_group_attachment" "graf-tg-attach-worker01" {
  target_group_arn            = aws_lb_target_group.graf-tg.arn
  target_id                   = aws_instance.Worker01_node.id
  port                        = 31300
  
}

# Add Grafana target group attachment for worker02
resource "aws_lb_target_group_attachment" "graf-tg-attach-worker02" {
  target_group_arn            = aws_lb_target_group.graf-tg.arn
  target_id                   = aws_instance.Worker02_node.id
  port                        = 31300
  
}

# Create Route 53
resource "aws_route53_zone" "ssmk_route53" {
  name = var.domain_name
  tags = {
    Environment = "ssmk_route53"
  }
}
resource "aws_route53_record" "ssmk_A_record" {
  zone_id = aws_route53_zone.ssmk_route53.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_lb.ssmk-lb.dns_name
    zone_id                = aws_lb.ssmk-lb.zone_id
    evaluate_target_health = false
  }
} */