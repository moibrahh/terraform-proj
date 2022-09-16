provider "aws" {
  region = "us-east-1"
    access_key = ""*****""
  secret_key = "********"
}
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
    tags = {
    Name = "VPC-1"
  }
}
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "Public-igw"
  }
}
resource "aws_route_table" "myvpc-rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }

  tags = {
    Name = "my-rt"
  }
}
resource "aws_subnet" "my-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-1"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my-subnet.id
  route_table_id = aws_route_table.myvpc-rt.id
}
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffick"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]   
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
    ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}
resource "aws_network_interface" "webserver-nic" {
  subnet_id       = aws_subnet.my-subnet.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.allow_web.id]
}
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.webserver-nic.id
  associate_with_private_ip = "10.0.0.50"
  depends_on =  [aws_internet_gateway.my-igw]
}
resource "aws_instance" "web-server-instance"{
    ami = "ami-052efd3df9dad4825"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "bizkit"
    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.webserver-nic.id
    }
    user_data = <<-EOF
               #!/bin/bash 
               sudu apt update -y
               sudu apt install apache2 -y
               sudu systemct1 start apache2
               sudo bash -c 'echo my very first webserver > var/www/html/index.html'
               EOF
    tags = {
      Name = "web-server"
    }
}