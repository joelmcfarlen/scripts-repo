import boto3
import csv
from datetime import datetime, timedelta

def get_s3_access_by_role(role_name, days=7, output_csv='s3_access_report.csv'):
    # Initialize Boto3 clients
    cloudtrail_client = boto3.client('cloudtrail')
    s3_client = boto3.client('s3')

    # Ensure CloudTrail is enabled and logging
    trails = cloudtrail_client.describe_trails()['trailList']
    if not trails:
        print("No CloudTrail trail found. Please set up CloudTrail to monitor S3 accesses.")
        return

    # Collect events from the last 'days' days
    start_date = datetime.now() - timedelta(days=days)
    events = cloudtrail_client.lookup_events(
        LookupAttributes=[
            {
                'AttributeKey': 'ResourceType',
                'AttributeValue': 'AWS::S3::Object'
            },
            {
                'AttributeKey': 'ReadOnly',
                'AttributeValue': 'false'  # Change to 'true' if you only want read access
            }
        ],
        StartTime=start_date,
        EndTime=datetime.now(),
        MaxResults=50  # Increase as needed
    )

    # Filter events by role
    bucket_access = {}
    for event in events['Events']:
        if role_name in event['Username']:
            bucket_name = event['Resources'][0]['ResourceName']
            if bucket_name not in bucket_access:
                bucket_access[bucket_name] = 0
            bucket_access[bucket_name] += 1

    # Write results to CSV
    with open(output_csv, 'w', newline='') as csvfile:
        fieldnames = ['Bucket Name', 'Access Count']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        for bucket, count in bucket_access.items():
            writer.writerow({'Bucket Name': bucket, 'Access Count': count})

    print(f"Report generated: {output_csv}")

if __name__ == "__main__":
    # Change 'YourIAMRoleName' to the role you want to check
    get_s3_access_by_role('djo-motionmd-prod-app-iam-role-IamRole-WGGT640CXU05')
