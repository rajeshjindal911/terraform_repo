variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  #default = "roche"
}

variable "roche_cidr" {
  type = string
  #default = "10.0.0.0/16"
  }

variable "azs" {
  type = list(string)
  #default = ["ap-south-1a","ap-south-1b","ap-south-1c"]
  }
variable "public_sub" {
  type = list(string)
  #default = ["10.0.0.0/24","10.0.1.0/24","10.0.2.0/24"]
  }

variable "private_sub" {
  type = list(string)
  #default = ["10.0.3.0/24","10.0.4.0/24","10.0.5.0/24"]
  }