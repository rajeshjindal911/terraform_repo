provider "aws" {
access_key = var.access_key
secret_key = var.secret_key
region = "ap-south-1"
}

locals {
  common_tags = {
   Name = "master_card"
   owner = "Rajesh Jindal"
}
}

resource "aws_vpc" "master_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = local.common_tags
}

resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.master_VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Public_A"
  }
}

resource "aws_subnet" "public_B" {
  vpc_id     = aws_vpc.master_VPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1c"
   tags = {
    Name = "Public_B"
  }
}

resource "aws_subnet" "private_A" {
  vpc_id     = aws_vpc.master_VPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
   tags = {
    Name = "Private_A"
  }
}

resource "aws_subnet" "private_B" {
  vpc_id     = aws_vpc.master_VPC.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-south-1b"
   tags = {
    Name = "Private_B"
  }
}

resource "aws_internet_gateway" "master_IGW" {
  vpc_id = aws_vpc.master_VPC.id
  tags = local.common_tags
}

resource "aws_route_table" "master_route" {
  vpc_id = aws_vpc.master_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.master_IGW.id
  }
    tags = {
    Name = "Public_Route"
  }
}

resource "aws_route_table_association" "Public_rt" {
  subnet_id      = aws_subnet.public_B.id
  route_table_id = aws_route_table.master_route.id
}

resource "aws_route_table_association" "Public_rt_b" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.master_route.id
}

resource "aws_eip" "master_eip" {
  vpc      = true
   tags = {
    Name = "master_EIP"
  }

}

resource "aws_nat_gateway" "master_GW" {
  allocation_id = aws_eip.master_eip.id
  subnet_id     = aws_subnet.public_B.id
   tags = {
    Name = "master_GW"
  }
}

resource "aws_route_table" "master_private" {
  vpc_id = aws_vpc.master_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.master_GW.id
  }
    tags = {
    Name = "Private_Route"
  }
}

resource "aws_route_table_association" "Private_rt" {
  subnet_id      = aws_subnet.private_A.id
  route_table_id = aws_route_table.master_private.id
}

resource "aws_route_table_association" "Private_rt_b" {
  subnet_id      = aws_subnet.private_B.id
  route_table_id = aws_route_table.master_private.id
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

resource "aws_instance" "master_ec2" {
  ami           = "ami-068d43a544160b7ef"
  instance_type = "t2.micro"
  key_name = var.key
  security_groups = [aws_security_group.master_sg.id]
  subnet_id = aws_subnet.private_B.id
  user_data = file("first_app.sh")
  tags = {
    Name = "master_ec2"
  }
}

resource "aws_lb" "master_elb" {
  name               = "masterelb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.master_sg.id]
  subnets            = [aws_subnet.public_a.id,aws_subnet.public_B.id]

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

resource "aws_ami_from_instance" "master_AMI" {
  name               = "master_AMI"
  source_instance_id = aws_instance.master_ec2.id
  tags = {
    Name = "master_AMI"
  }
}

resource "aws_launch_configuration" "master_conf" {
  name          = "master_config"
  image_id      = aws_ami_from_instance.master_AMI.id
  instance_type = "t2.micro"
  security_groups    = [aws_security_group.master_sg.id]
  key_name = var.key
}

resource "aws_autoscaling_group" "Master_ASG" {
  name                      = "MAster_ASG"
  max_size                  = 3
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = aws_launch_configuration.master_conf.id
  vpc_zone_identifier       = [aws_subnet.private_B.id]
}

resource "aws_autoscaling_attachment" "Master_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.Master_ASG.id
  alb_target_group_arn   = aws_lb_target_group.masterTG.arn
}

output "elb_dns" {
   value = aws_lb.master_elb.dns_name
}
