import boto3
import csv
import datetime
import json

def get_s3_access_by_role(role_arn, days):
    cloudtrail_client = boto3.client('cloudtrail')
    start_time = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=days)
    end_time = datetime.datetime.now(datetime.timezone.utc)
    
    events = []
    next_token = None

    while True:
        if next_token:
            response = cloudtrail_client.lookup_events(
                StartTime=start_time,
                EndTime=end_time,
                LookupAttributes=[
                    {'AttributeKey': 'EventSource', 'AttributeValue': 's3.amazonaws.com'},
                    {'AttributeKey': 'UserIdentityArn', 'AttributeValue': role_arn}
                ],
                NextToken=next_token
            )
        else:
            response = cloudtrail_client.lookup_events(
                StartTime=start_time,
                EndTime=end_time,
                LookupAttributes=[
                    {'AttributeKey': 'EventSource', 'AttributeValue': 's3.amazonaws.com'},
                    {'AttributeKey': 'UserIdentityArn', 'AttributeValue': role_arn}
                ]
            )
        
        events.extend(response['Events'])
        
        next_token = response.get('NextToken')
        if not next_token:
            break

    return events

def extract_bucket_name(event):
    cloud_trail_event = json.loads(event.get('CloudTrailEvent', '{}'))
    request_parameters = cloud_trail_event.get('requestParameters', {})

    if 'bucketName' in request_parameters:
        return request_parameters['bucketName']
    elif 'bucket' in request_parameters and 'name' in request_parameters['bucket']:
        return request_parameters['bucket']['name']
    return 'N/A'

def write_csv(events, filename='s3_access_by_role.csv'):
    with open(filename, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['EventTime', 'EventName', 'BucketName', 'Username', 'SourceIPAddress', 'AWSRegion', 'UserArn'])

        for event in events:
            event_time = event.get('EventTime')
            event_name = esvent.get('EventName')
            user_identity = event.get('Username', 'N/A')
            bucket_name = extract_bucket_name(event)
            source_ip_address = event.get('SourceIPAddress', 'N/A')
            aws_region = event.get('AWSRegion', 'N/A')
            user_arn = event.get('UserIdentityArn', 'N/A')

            writer.writerow([event_time, event_name, bucket_name, user_identity, source_ip_address, aws_region, user_arn])

if __name__ == "__main__":
    role_arn = "arn:aws:sts::220607497873:assumed-role/djo-motionmd-demo2-app-iam-role-IamRole-19QVSAMC9R17K"
    events = get_s3_access_by_role(role_arn, 30)  # Change the number of days as required
    write_csv(events)
    print("CSV report has been created successfully.")
