
provider "aws" {
    region = "us-east-1"  # region set to US east coast (N Virginia Location)
} 

variable vpc_cidr_block {}  
variable subnet_cidr_block {}
variable avail_zone {}      
variable env_prefix {}       
variable ip_address {}       # Internal IP address
variable instance_type {}    # EC2 t3.micro instance
variable "my_public_key" {}  # internal SSH key on localhost 

resource "aws_vpc" "myapp-vpc" { # virtual private network module
    cidr_block = var.vpc_cidr_block
      tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" { # subnet module for VPC
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
      tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {  # gateway module for VPC
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
      Name: "${var.env_prefix}-igw"
    }
}

resource "aws_default_route_table" "main_rtb" {  # route table for VPC to allow egree/ingress
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
       Name: "${var.env_prefix}-main-rtb"
    }
}

resource "aws_default_security_group" "default-sg" {   # SEC group to open/close ports on route table
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.ip_address]
    }

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
       Name: "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {   # loading up amazon linux image
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "ssh-key" { 
    key_name = "server-key"
    public_key = var.my_public_key
}

resource "aws_instance" "myapp-server" {    # creating EC2 instance and provisioning on AWS
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("entry-script.sh")
    
    tags = {
       Name: "${var.env_prefix}-server"
    }
}

