provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIA4SZHOBG5OKELMXLR"
  secret_key = "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"
  #shared_credentials_files = ["/Users/rajesh.cv.kumar/.aws/credentials"]
}

locals {
  name = "roche"
  }

#data "aws_availability_zone" "available" {
 # }
resource "aws_vpc" "roche_vpc" {
  cidr_block = var.roche_cidr
  tags = {
    Name = "${var.instance_name}-vpc"
  }
}

resource "aws_subnet" "roche_public" {
   vpc_id = aws_vpc.roche_vpc.id
   count = length(var.public_sub)
   availability_zone = var.azs[count.index]
   cidr_block = var.public_sub[count.index]
   map_public_ip_on_launch = true
   tags = {
     Name = "${var.instance_name}_public_sub-${count.index}"
   }
}

resource "aws_subnet" "roche_private" {
   vpc_id = aws_vpc.roche_vpc.id
   count = length(var.private_sub)
   availability_zone = var.azs[count.index]
   cidr_block = var.private_sub[count.index]
   tags = {
     Name = "${var.instance_name}_private_sub-${count.index}"
   }
}

resource "aws_internet_gateway" "roche_igw" {
      vpc_id = aws_vpc.roche_vpc.id
      tags = {
        Name = "${var.instance_name}_igw"
      }
  }

resource "aws_route_table" "roche_rt_public" {
  vpc_id = aws_vpc.roche_vpc.id
  tags = {
        Name = "${var.instance_name}_rt_public"
      }
}

resource "aws_route_table_association" "roche_rt_public_association" {
  count = 3
  route_table_id = aws_route_table.roche_rt_public.id
  subnet_id = aws_subnet.roche_public[count.index].id
  }

resource "aws_route" "roche_public_route" {
  route_table_id = aws_route_table.roche_rt_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.roche_igw.id
  
  }

resource "aws_route_table" "roche_rt_private" {
  vpc_id = aws_vpc.roche_vpc.id
  tags = {
        Name = "${var.instance_name}_rt_private"
      }
}

resource "aws_route_table_association" "roche_rt_private_association" {
  count = 3
  route_table_id = aws_route_table.roche_rt_private.id
  subnet_id = aws_subnet.roche_private[count.index].id
  }

resource "aws_eip" "roche_eip" {
  network_border_group = "ap-south-1"
}
resource "aws_nat_gateway" "roche_nat_gw" {
  subnet_id = aws_subnet.roche_public[0].id
  connectivity_type = "public"
  allocation_id = aws_eip.roche_eip.id
  depends_on = [ aws_eip.roche_eip ]
  tags = {
     Name = "${var.instance_name}_nat_gw"
  }
  
}

resource "aws_route" "roche_private_route" {
  route_table_id = aws_route_table.roche_rt_private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.roche_nat_gw.id
  
  }