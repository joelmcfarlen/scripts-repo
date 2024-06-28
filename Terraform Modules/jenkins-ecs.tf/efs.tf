resource "aws_efs_file_system" "ElasticFileSystem" {
  depends_on = [aws_security_group.EFSSecurityGroup]

  throughput_mode = "bursting"
  encrypted       = true
  performance_mode = "generalPurpose"

  tags = {
    Name = "momd-${terraform.workspace}-jenkins-efs"
  }
}

resource "aws_efs_access_point" "EFSAccessPoint" {
  file_system_id = aws_efs_file_system.ElasticFileSystem.id

  posix_user {
    uid = "0"
    gid = "0"
  }

  root_directory {
    creation_info {
      owner_gid     = "1000"
      owner_uid     = "1000"
      permissions   = "0755"
    }
    path = "/"
  }
}

resource "aws_security_group" "EFSSecurityGroup" {
  name        = "momd-${terraform.workspace}-jenkins-efs-sg"
  description = "Allow NFS access to EFS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.common.cidr_block]
  }

  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.common.cidr_block]
  }
}

resource "aws_efs_mount_target" "MountTargetAZ1" {
  subnet_id         = element(var.private_subnet_id, 0)
  file_system_id    = aws_efs_file_system.ElasticFileSystem.id
  security_groups   = [aws_security_group.EFSSecurityGroup.id]
}

resource "aws_efs_mount_target" "MountTargetAZ2" {
  subnet_id         = element(var.private_subnet_id, 1)
  file_system_id    = aws_efs_file_system.ElasticFileSystem.id
  security_groups   = [aws_security_group.EFSSecurityGroup.id]
}

resource "aws_efs_mount_target" "MountTargetAZ3" {
  subnet_id         = element(var.private_subnet_id, 2)
  file_system_id    = aws_efs_file_system.ElasticFileSystem.id
  security_groups   = [aws_security_group.EFSSecurityGroup.id]
}

resource "aws_cloudwatch_metric_alarm" "EFSBurstCreditsAlarm" {
  alarm_name          = "momd-${terraform.workspace}-jenkins-efs-burst-credits"
  evaluation_periods  = var.cw_burst_credit_period
  comparison_operator = "LessThanThreshold"
  threshold           = var.cw_burst_credit_threshold
  period              = 3600
  statistic           = "Minimum"
  metric_name         = "BurstCreditBalance"
  namespace           = "AWS/EFS"
  unit                = "Bytes"
  dimensions = {
    FileSystemId = aws_efs_file_system.ElasticFileSystem.id
  }
}
