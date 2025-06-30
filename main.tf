terraform {
  backend "s3" {
    bucket         = "glowing20250630"
    key            = "global/infra/terraform.tfstate"
    region         = "sa-east-1"
    dynamodb_table = "terraform-lock-table-desafio-final"
  }
}

provider "aws" {
  region = "sa-east-1"
}

provider "tls" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "glowing20250630"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-lock-table-desafio-final"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "tls_private_key" "chave_aleatoria_ed" {
  algorithm = "ED25519"
}

resource "aws_ssm_parameter" "chave_publica_ssm" {
  name  = "/desafio-final/chave_ed.pub"
  type  = "String"
  value = tls_private_key.chave_aleatoria_ed.public_key_openssh
}

resource "aws_ssm_parameter" "chave_privada_ssm" {
  name  = "/desafio-final/chave_ed.pem"
  type  = "SecureString"
  value = tls_private_key.chave_aleatoria_ed.private_key_pem
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "chave-desafio-final-ed25519"
  public_key = tls_private_key.chave_aleatoria_ed.public_key_openssh
}

data "aws_vpc" "default" {
  default = true
}
data "aws_subnet" "public" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "sa-east-1a"
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

resource "aws_s3_bucket" "bucket_da_app" {
  bucket = "bucket-app-final-${random_id.sufixo.hex}"
}
resource "random_id" "sufixo" {
  byte_length = 8
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh-sg-final"
  description = "Permite conexões SSH"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["177.138.25.205/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_s3_role" {
  name               = "ec2-s3-access-role-final"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "s3_access" {
  name   = "s3-access-policy-final"
  role   = aws_iam_role.ec2_s3_role.id
  policy = data.aws_iam_policy_document.s3_access_policy.json
}
data "aws_iam_policy_document" "s3_access_policy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.bucket_da_app.arn]
  }
  statement {
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.bucket_da_app.arn}/*"]
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-access-profile-final"
  role = aws_iam_role.ec2_s3_role.name
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "servidor_principal" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type           = "t2.micro"
  subnet_id               = data.aws_subnet.public.id
  key_name                = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids  = [aws_security_group.allow_ssh.id]
  iam_instance_profile    = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  tags = {
    Name = "Servidor-Desafio-Final"
  }
}
