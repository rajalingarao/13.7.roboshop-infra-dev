  resource "aws_instance" "bastion" {

  ami = data.aws_ami.ami_info.id
  instance_type          = "t3.micro"
  # vpc_security_group_ids = [local.bastion_sg_id]
  # subnet_id              = local.public_subnet_id
  vpc_security_group_ids =  [local.bastion_sg_id]
  subnet_id              =  local.public_subnet_id
  user_data              =  file("${path.module}/bastion.sh")

  # need more for terraform
  root_block_device  {
      encrypted             = false
      volume_type           = "gp3"
      volume_size           = 120
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
    }

  tags = merge(
    var.common_tags,
    var.bastion_tags,
    {
        Name = local.resource_name
    }
  )
}