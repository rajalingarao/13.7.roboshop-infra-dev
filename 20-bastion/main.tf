module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.ami_info.id
  name = local.resource_name
  instance_type          = "t3.micro"
  # vpc_security_group_ids = [local.bastion_sg_id]
  # subnet_id              = local.public_subnet_id
  vpc_security_group_ids = ["sg-09c7c70bd56f0d58b"]
  subnet_id              = "subnet-0a3b249c1f344ef36"

  tags = merge(
    var.common_tags,
    var.bastion_tags,
    {
        Name = local.resource_name
    }
  )
}