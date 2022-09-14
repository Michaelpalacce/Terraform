provider "aws" {
  region = "eu-west-1"
}

############ S3 #################
resource "aws_s3_bucket" "prod_sgenov_bucket" {
  bucket = "sgenov-terraform"

  tags = {
    Terraform: "true"
  }
}

resource "aws_s3_bucket_acl" "prod_sgenov_bucket_acl" {
  bucket  = "sgenov-terraform"
  acl     = "private"
}

############ S3 #################

############ VPC ################

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_aza" {
  availability_zone = "eu-west-1a"

  tags = {
    Terraform: "true"
  }
}

resource "aws_default_subnet" "default_azb" {
  availability_zone = "eu-west-1b"

  tags = {
    Terraform: "true"
  }
}

############ VPC ################

############ SG ################

resource "aws_security_group" "prod_web" {
  name        = "prod_web"
  description = "Allow standard http and https ports ingress and everything egress"

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform: "true"
  }
}

############ SG ################

############ INSTANCES #########

# Following AMI is a bitnami packaged nginx
# ami-0db1d473d1fdc1dfc

resource "aws_instance" "prod_web" {
  count         = 2

  ami           = "ami-0db1d473d1fdc1dfc"
  instance_type = "t2.nano"

  vpc_security_group_ids = [
    aws_security_group.prod_web.id
  ]

  tags = {
    Terraform: "true"
  }
}

############ INSTANCES #########

############ EIP ###############
# Decoupled in the case you would like to remove a eip from an instance
resource "aws_eip_association" "prod_web" {
  instance_id = aws_instance.prod_web.0.id
  allocation_id = aws_eip.prod_web.id
}

resource "aws_eip" "prod_web" {
  tags = {
    Terraform: "true"
  }
}

############ EIP ###############

############ ELB ###############

resource "aws_elb" "prod_web" {
  name            = "prod-web"
  instances       = aws_instance.prod_web.*.id

  subnets         = [aws_default_subnet.default_aza.id, aws_default_subnet.default_azb.id]

  security_groups = [aws_security_group.prod_web.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

#  listener {
#    instance_port     = 443
#    instance_protocol = "https"
#    lb_port           = 443
#    lb_protocol       = "https"
#  }

  tags = {
    Terraform: "true"
  }
}

############ ELB ###############
