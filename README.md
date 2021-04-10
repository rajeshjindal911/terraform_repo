# terraform_repo
i have bulit this code in Terraform v.14
in this i have created Auto-scaling group with ELastic load Balancer.
All my Ec2 resource will be in private subnet.
ELB will be in public subnet
in this Project.tf contains all the configuration code.
to insert user data i have created a first_app.sh file.
variable.tf contains the Variables. 
once you will run the terraform apply command. so in the end you will get the "ELB_DNS_NAME".
Please go-through the code for further information.
