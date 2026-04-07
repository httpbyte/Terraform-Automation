resource "aws_default_security_group" "default-sg" {   # SEC group to open/close ports on route table
    vpc_id = var.vpc_id

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
        values = [var.image_name]
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

    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("entry-script.sh")

    connection {
        type = "ssh"
        host = self.public_ip
        user = "ec2-user"
        private_key = var.my_private_key
    }

    provisioner "file" {
        source = "entry-script.sh"
        destination = "/home/ec2-user/entry-script.sh"
    }
    
    provisioner "remote-exec" {
        inline = [
            "chmod +x /home/ec2-user/entry-script.sh",
            "bash /home/ec2-user/entry-script.sh"
        ]
    }

    provisioner "local-exec" {
        command = "echo ${self.public_ip} > test.txt"
    }
        
    tags = {
       Name: "${var.env_prefix}-server"
    }
}