 module "gitlab_asg" {
  source = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = var.name

  lc_name = "${var.name}-lc"

  image_id        = data.aws_ami.amazon_linux.id
  instance_type   = var.instance_type
  security_groups = [module.gitlab_ec2_http_sg.this_security_group_id, 
                     module.gitlab_ssh_sg.this_security_group_id, 
                     module.all_egress_sg.this_security_group_id]

  load_balancers  = [module.elb.this_elb_id]
  user_data                   = "${base64encode(data.template_file.user_data.rendered)}"

  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "100"
      delete_on_termination = true
    },
  ]

  root_block_device = [
    {
      volume_size = "100"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "${var.name}-asg"
  vpc_zone_identifier       = var.vpc.private_subnets
  key_name                  = var.ssh_keypair
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "devops"
      propagate_at_launch = true
    },
  ]
}







