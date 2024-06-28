data "aws_vpc" "common" {
  tags = {
    Name = "djo-motionmd-vpc-common"
  }
}