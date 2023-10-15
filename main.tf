provider "aws" {
  region = "us-east-1"  
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"   
  tags = {
    Name = "main-instance"
  }
}

resource "aws_ecr_repository" "my_ecr_repo" {
  name = "ecr-repo"
}

resource "aws_iam_role" "eks_iam_role" {
  name = "my-eks-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_iam_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_iam_role.name
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids = [var.subnet_id_1, var.subnet_id_2]  #referencing the subnet from the variables files
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly-EKS,
  ]
}

resource "aws_s3_bucket" "my_s3_bucket" {
  bucket = "terraform-state-files"
  acl    = "private"

  versioning {
    enabled = true  #useful to adjust version changes
  }

  tags = {
    Name = "my-terraform-state-files-bucket"
  }
}
