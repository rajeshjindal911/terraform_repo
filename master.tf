provider "aws" {
access_key = "AKIAJB2CF7DGOA5QKC7Q"
secret_key = "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"
region = "ap-south-1"
}

resource "aws_vpc" "master_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "master"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.master_VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Public_subnet"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.master_VPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Public_subnet_b"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.master_VPC.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private_subnet"
  }
}

resource "aws_security_group" "master_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.master_VPC.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "master_sg"
  }
}

resource "aws_internet_gateway" "master_IGW" {
  vpc_id = aws_vpc.master_VPC.id

  tags = {
    Name = "master_IGW"
  }
}

resource "aws_route_table" "master_rt" {
  vpc_id = aws_vpc.master_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.master_IGW.id
  }


  tags = {
    Name = "master_rt"
  }
}

resource "aws_route_table_association" "Public_rt" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.master_rt.id
}

resource "aws_route_table_association" "Public_rt_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.master_rt.id
}

resource "aws_instance" "master_ec2" {
  ami           = "ami-0eeb03e72075b9bcc"
  instance_type = "t2.micro"
  key_name = "key_for_AD"
  security_groups = [aws_security_group.master_sg.id]
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = "true"
  user_data = "${file("first_app.sh")}"
  tags = {
    Name = "first_web"
  }
}

resource "aws_instance" "master_second" {
  ami           = "ami-0eeb03e72075b9bcc"
  instance_type = "t2.micro"
  key_name = "key_for_AD"
  security_groups = [aws_security_group.master_sg.id]
  subnet_id = aws_subnet.public_subnet_b.id
  associate_public_ip_address = "true"
  user_data = "${file("second_app.sh")}"
  tags = {
    Name = "second_web"
  }
}

resource "aws_lb" "master_elb" {
  name               = "masterelb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.master_sg.id]
  subnets            = [aws_subnet.public_subnet.id,aws_subnet.public_subnet_b.id]

  enable_deletion_protection = true
  tags = {
    Name = "masterelb"
  }
}
resource "aws_lb_listener" "master_listener" {
  load_balancer_arn = aws_lb.master_elb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.masterTG.arn
    }
  }


resource "aws_lb_target_group" "masterTG" {
  name        = "masterTG"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.master_VPC.id
}

resource "aws_lb_target_group_attachment" "master_TG" {
  target_group_arn = aws_lb_target_group.masterTG.arn
  target_id        = aws_instance.master_ec2.id
  port             = 80
}
