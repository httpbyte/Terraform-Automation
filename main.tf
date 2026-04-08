provider "aws" {
    region = "us-east-1"  # region set to US east coast (N Virginia Location)
}

module "vpc" {  # updated vpc module to use terraform-aws-modules/vpc/aws 
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = var.vpc_cidr_block

  azs             = [var.avail_zone]
  public_subnets  = [var.subnet_cidr_block]
  public_subnet_tags = {Name = "${var.env_prefix}-subnet-1"}

  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

module "myapp_server" {     # webserver module
    source = "./modules/webserver"
    vpc_id = module.vpc.vpc_id
    ip_address = var.ip_address
    env_prefix = var.env_prefix
    image_name = var.image_name
    my_public_key = var.my_public_key
    instance_type = var.instance_type
    avail_zone = var.avail_zone
    subnet_id = module.vpc.public_subnets[0]
    my_private_key = var.my_private_key
}