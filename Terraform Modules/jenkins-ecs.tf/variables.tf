locals {
  tags = merge({
    Application = var.app
    cfngin_namespace = "TBU-${terraform.workspace}"
    TerraformManaged = "true"
  }, var.tags)
}

// General Config
variable "aws_region" {
   description = "Region in AWS to deploy to"
   type        = string
 }

variable "aws_account_id" {
   description = "AWS account ID"
   type        = string
 }

variable "tags" {
  description = "Tags map to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "app" {
  description = "Name of the application"
  type        = string
}

variable "cw_burst_credit_period" {
  description = "Peroid which burst credits are consumed if needed"
  type        = string
}

variable "cw_burst_credit_threshold" {
  description = "Threshold which burst credits can be consumed if needed"
  type        = string
}

variable "image_id" {
  description = "Threshold which burst credits can be consumed if needed"
  type        = string
}

// ALB
variable "jenkins_alb_cert" {
  description = "Arn of ELB Listener"
  type        = string
}

// S3 Bucket
variable "file_upload_bucket_name" {
  description = "Unique name of new S3 buckets to upload scripts and config files to"
  type        = string
}

// Networking
variable "vpc_id" {
  description = "VPC ID for Jenkins and security group"
  type        = string
}

variable "private_subnet_id" {
  description = "Subnet ID for Jenkins buid instance"
  type        = list(string)
}

variable "public_subnet_id" {
  description = "Subnet ID for Jenkins buid instance"
  type        = list(string)
}

// DNS
variable "hosted_zone_name" {
  description = "Hostzone name in R53"
  type        = string
}

variable "hosted_zone_id" {
  description = "Hostzone name in R53"
  type        = string
}

// Monitoring
variable "pagerduty_sns_topic" {
  description = "Arn of the SNS Topic to send alerts to if Jenkins fails"
  type        = string
}
