resource "aws_launch_template" "asg" {
  name                    =  "${var.COMPONENT}-${var.ENV}-template"
  image_id                = data.aws_ami.ami.id
  instance_type           = var.INSTANCE_TYPE
  vpc_security_group_ids  = [aws_security_group.allow-component.id]
}


resource "aws_autoscaling_group" "asg" {
    name                    = "${var.COMPONENT}-${var.ENV}-asg"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  force_delete              = true
  launch_template {
    id                      = aws_launch_template.asg.id
    version                 = "$Latest"
  }
  vpc_zone_identifier       = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNETS
  target_group_arns         = [aws_lb_target_group.tg.arn]

  tag {
    key                     = "Name"
    propagate_at_launch     = true
    value                   = "${var.COMPONENT}-${var.ENV}"
  }
}

resource "aws_lb_target_group" "tg" {
  name                       = "${var.COMPONENT}-${var.ENV}-tg"
  port                       = var.PORT
  protocol                   = "HTTP"
  vpc_id                     = data.terraform_remote_state.vpc.outputs.VPC_ID
  health_check {
    path                     = var.HEALTH
  }
}

resource "aws_security_group" "allow-component" {
  name                       = "allow-${var.COMPONENT}-${var.ENV}-sg"
  description                = "allow-${var.COMPONENT}-${var.ENV}-sg"
  vpc_id                     = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description             = "SSH"
    from_port               = 22
    to_port                 = 22
    protocol                = "tcp"
    cidr_blocks             = [data.terraform_remote_state.vpc.outputs.VPC_CIDR, data.terraform_remote_state.vpc.outputs.DEFAULT_VPC_CIDR]
  }
  ingress {
    description             = "HTTP"
    from_port               = var.PORT
    to_port                 = var.PORT
    protocol                = "tcp"
    cidr_blocks             = [data.terraform_remote_state.vpc.outputs.VPC_CIDR]
  }
  egress {
    from_port              = 0
    to_port                = 0
    protocol               =  "-1"
    cidr_blocks            = ["0.0.0.0/0"]
  }

  tags                     = {
    Name                  = "allow-${var.COMPONENT}-${var.ENV}-sg"
  }
}