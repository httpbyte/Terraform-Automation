#!/bin/bash
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker
sleep 10                                
sudo systemctl is-active docker
sudo usermod -aG docker ec2-user
sudo docker run -d -p 8080:80 nginx