provider "aws" {
    region = "us-east-1"  # region set to US east coast (N Virginia Location)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "myapp_server" {     # webserver module
    source = "./modules/webserver"
    vpc_id = aws_vpc.myapp-vpc.id
    ip_address = var.ip_address
    env_prefix = var.env_prefix
    image_name = var.image_name
    my_public_key = var.my_public_key
    instance_type = var.instance_type
    avail_zone = var.avail_zone
    subnet_id = module.myapp_subnet.subnet.id
    # default_sg_id = aws_default_security_group.default-sg.id
    my_private_key = var.my_private_key
}