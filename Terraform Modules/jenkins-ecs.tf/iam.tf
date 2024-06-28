resource "aws_iam_role" "ECSJenkinsTaskRole" {
  name                = "momd-${terraform.workspace}-jenkins-ecs-iam-role"
  description         = "IAM role for Jenkins ECS"
  assume_role_policy  = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
          "StringEquals": {
            "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  }
EOF
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
}

resource "aws_iam_role_policy" "jenkins_all_the_access" {
  name   = "jenkins-all-the-access"
  role   = aws_iam_role.ECSJenkinsTaskRole.name

  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "*"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        }
    ]
}
  EOF
}