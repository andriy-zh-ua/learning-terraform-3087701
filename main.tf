data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [module.security-group-blog-sg.security_group_id]

  tags = {
    Name = "HelloWorld"
  }
}

# Security group for blog, where HTTP and HTTPS are allowed
module "security-group-blog-sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "5.3.1"
  name        = "new-blog-sg"
  description = "Security group for blog, where HTTP and HTTPS are allowed"
  vpc_id      = data.aws_vpc.default.id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

# Security group for blog, where HTTP and HTTPS are allowed
resource "aws_security_group" "blog" {
  name        = "blog-sg"
  description = "Security group for blog, where HTTP and HTTPS are allowed"
  vpc_id      = data.aws_vpc.default.id
}

# Allow HTTP traffic
resource "aws_security_group_rule" "blog_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Allow all IP addresses
  security_group_id = aws_security_group.blog.id
}

# Allow HTTPS traffic
resource "aws_security_group_rule" "blog_https_in" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Allow all IP addresses
  security_group_id = aws_security_group.blog.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "blog_everything_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] # Allow all IP addresses
  security_group_id = aws_security_group.blog.id
}