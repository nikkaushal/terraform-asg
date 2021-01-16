data "aws_ami" "ami" {
  most_recent         = true
  owners              = ["099034111737"]
}

data "terraform_remote_state" "vpc" {
  backend             = "s3"
  config              = {
    bucket            = var.bucket
    key               = "vpc/${var.ENV}/terraform.tfstate"
    region            = var.region
  }
}