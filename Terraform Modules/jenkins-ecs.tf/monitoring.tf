
resource "aws_synthetics_canary" "jenkins_canary" {
  name                  = "jenkins-canary"
  artifact_s3_location  = "s3://${var.file_upload_bucket_name}/packages/jenkinscanary/"
  zip_file              = data.archive_file.jenkins_canary_script.output_path
  handler               = "jenkins_canary_script.handler"
  runtime_version       = "syn-python-selenium-2.1"
  execution_role_arn    = aws_iam_role.canary_execution_role.arn
  start_canary          = true

  schedule {
    expression          = "rate(5 minutes)"
  }
}

resource "aws_iam_role" "canary_execution_role" {
  name = "jenkins-canary-execution-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "lambda.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "jenkins-canary-execution-role"
  }
}

resource "aws_iam_policy" "canary_execution_policy" {
  name        = "jenkins-canary-execution-policy"
  description = "Policy for CloudWatch Synthetics canary execution"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": [
                "*"        
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "*"        
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "xray:PutTraceSegments"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": "cloudwatch:PutMetricData",
            "Condition": {
               "StringEquals": {
                "cloudwatch:namespace": "CloudWatchSynthetics"
               }
            }
        }
    ]
  })
}

resource "aws_iam_policy_attachment" "canary_execution_policy_attachment" {
  name       = "jenkins-canary-execution-policy-attachment"
  roles      = [aws_iam_role.canary_execution_role.name]
  policy_arn = aws_iam_policy.canary_execution_policy.arn
}


data "archive_file" "jenkins_canary_script" {
  type        = "zip"
  output_path = "components/jenkins_canary_script.zip"
  
  source {
    content  = <<-EOT
from aws_synthetics.selenium import synthetics_webdriver as webdriver
from aws_synthetics.common import synthetics_logger as logger

def custom_selenium_script():
    # create a browser instance
    browser = webdriver.Chrome()
    
    # Load the endpoint
    browser.get('https://jenkins.${var.hosted_zone_name}')
    logger.info('navigated to home page')
    
    # Close the browser
    browser.quit()

# entry point for the canary
def handler(event, context):
    return custom_selenium_script()

    EOT
    filename = "python/jenkins_canary_script.py"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_http_alarm" {
  alarm_name          = "momd-jenkins-ecs-http-alarm"
  actions_enabled     = !var.silence_alarms
  ok_actions          = [var.pagerduty_sns_topic]
  alarm_actions       = [var.pagerduty_sns_topic]
  insufficient_data_actions = []

  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  statistic           = "Average"

  dimensions = {
    CanaryName  = "jenkins-canary"
  }

  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
}
