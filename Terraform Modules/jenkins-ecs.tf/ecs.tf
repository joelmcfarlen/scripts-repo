
resource "aws_kms_key" "KMSJenkinsKey" {
  description             = "kms key for jenkins ecs"
  deletion_window_in_days = 7
  tags = {
    Name = "momd-${terraform.workspace}-jenkins-ecs-kms-key"
  }
}

resource "aws_kms_key" "KMSJenkinsLogsKey" {
  description             = "kms key for jenkins ecs"
  deletion_window_in_days = 7
  tags = {
    Name = "momd-${terraform.workspace}-jenkins-logs-kms-key"
  }

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.aws_account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.${var.aws_region}.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    }    
  ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "JenkinsLogGroup" {
  name     = "momd-${terraform.workspace}-jenkins-ecs-log-group"
  kms_key_id = aws_kms_key.KMSJenkinsLogsKey.arn
  depends_on = [aws_kms_key.KMSJenkinsLogsKey]
  retention_in_days = 14
}

resource "aws_ecs_cluster" "ECSJenkinsCluster" {
  name = "momd-${terraform.workspace}-jenkins-cluster"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.KMSJenkinsKey.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.JenkinsLogGroup.name
      }
    }
  }
}

resource "aws_ecs_task_definition" "ECSJenkinsTaskDef" {
  family                   = "jenkins"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096

  execution_role_arn = aws_iam_role.ECSJenkinsTaskRole.arn
  task_role_arn      = aws_iam_role.ECSJenkinsTaskRole.arn

  container_definitions = jsonencode([
    {
      essential = true
      name      = "momd-${terraform.workspace}-jenkins-task-def"
      portMappings = [
        { containerPort = 8080 },
        { containerPort = 50000 },
      ]
      environment = [
        { name = "JAVA_OPTS", value = "-Djenkins.install.runSetupWizard=false" },
      ]
      mountPoints = [
        {
          containerPath = "/var/jenkins_home"
          readOnly      = false
          sourceVolume  = "jenkins-efs"
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"              = aws_cloudwatch_log_group.JenkinsLogGroup.name
          "awslogs-region"             = data.aws_region.current.name
          "awslogs-create-group"       = "true"
          "awslogs-stream-prefix"      = "jenkins"
        }
      }
      image = var.image_id
    },
  ])

  volume {
    name = "jenkins-efs"
    efs_volume_configuration {
      authorization_config {
        access_point_id = aws_efs_access_point.EFSAccessPoint.id
        iam            = "ENABLED"
      }
      file_system_id   = aws_efs_file_system.ElasticFileSystem.id
      root_directory   = "/"
      transit_encryption = "ENABLED"
    }
  }
  
  tags = {
    Name = "momd-${terraform.workspace}-jenkins-taskdef"
  }

}

resource "aws_security_group" "JenkinsECSSecurityGroup" {
  name        = "momd-${terraform.workspace}-jenkins-ecs-sg"
  description = "Allow NFS access to EFS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.common.cidr_block]
  }

  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.common.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "JenkinsECSService" {
  name            = "momd-${terraform.workspace}-jenkins-ecs-service"
  cluster         = "momd-${terraform.workspace}-jenkins-cluster"
  task_definition = aws_ecs_task_definition.ECSJenkinsTaskDef.arn
  launch_type     = "FARGATE"
  enable_execute_command = true
  desired_count   = 1
  health_check_grace_period_seconds = 300

  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets = var.private_subnet_id
    security_groups = [
      aws_security_group.JenkinsECSSecurityGroup.id,
    ]
  }

  load_balancer {
    container_name   = "momd-${terraform.workspace}-jenkins-task-def"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.jenkins_ecs_target_group.arn
  }
}
