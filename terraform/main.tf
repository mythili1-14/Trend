terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Or your preferred AWS region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "trend-vpc"
  }
}

resource "aws_subnet" "public" {
  count = 2
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "trend-public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "trend-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "trend-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

data "aws_availability_zones" "available" {}


resource "aws_iam_role" "eks_cluster_role" {
  name = "trend-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "main" {
  name     = "trend-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
# Add this block to your main.tf file
resource "aws_eks_node_group" "trend_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "trend-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.public[*].id
  instance_types  = ["t2.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
  ]
}

# Add IAM Role for EKS Worker Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "trend-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach IAM Policies for Worker Nodes
resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ec2_container_registry_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "jenkins_ec2_role" {
  name = "trend-jenkins-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "trend-jenkins-profile"
  role = aws_iam_role.jenkins_ec2_role.name
}


resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow inbound traffic to Jenkins server"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Limit this to your IP for security
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Limit this to your IP for security
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins_server" {
  ami           = "ami-0360c520857e3138f" # Ubuntu Server 20.04 LTS (HVM)
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public[0].id
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
  key_name      = "your-key-pair-name" # Replace with your EC2 key pair name

  # Corrected line: reference the security group by its ID
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOT
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y docker.io git openjdk-11-jdk
    sudo systemctl start docker
    sudo usermod -a -G docker ubuntu
    
    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt-get update -y
    sudo apt-get install -y jenkins
    sudo systemctl start jenkins
  EOT
  tags = {
    Name = "JenkinsServer"
  }
}


output "jenkins_public_ip" {
  value       = aws_instance.jenkins_server.public_ip
  description = "Public IP of the Jenkins server"
}

output "eks_cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "Name of the EKS cluster"
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}
