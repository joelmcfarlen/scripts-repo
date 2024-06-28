
terraform {
  backend "s3" {
    key = "jenkins-ecs.tfstate"
  }
}

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}