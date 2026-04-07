provider "aws" {
    region = "us-east-1"  # region set to US east coast (N Virginia Location)
}

resource "aws_vpc" "myapp-vpc" { # virtual private network module
    cidr_block = var.vpc_cidr_block
      tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

module "myapp_subnet" {     # subnet module
    source = "./modules/subnet"
    subnet_cidr_block = var.subnet_cidr_block
    avail_zone = var.avail_zone
    env_prefix = var.env_prefix
    vpc_id = aws_vpc.myapp-vpc.id
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
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