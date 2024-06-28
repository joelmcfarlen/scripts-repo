// Networking
vpc_id              = "vpc-"    
private_subnet_id   = [
    "subnet-",
    "subnet-",
    "subnet-"
    ]
public_subnet_id    = [
    "subnet-",
    "subnet-",
    "subnet-"
    ]

// DNS
hosted_zone_name = ".com"

// General Config
aws_account_id          = ""
aws_region              = ""  
app                     = ""
file_upload_bucket_name = "BUCKET-NAME"
pagerduty_sns_topic     = "arn:aws:sns:"

// EFS
cw_burst_credit_threshold = "1000000000000"
cw_burst_credit_period    = "12"

// ECS
image_id = ""

// ALB
hosted_zone_id   = ""
jenkins_alb_cert = "arn:aws:acm:"