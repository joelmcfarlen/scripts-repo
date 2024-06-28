import boto3
import datetime
import csv

def get_s3_accessed_buckets(instance_id, days=2):
    client = boto3.client('cloudtrail')
    end_time = datetime.datetime.now(datetime.timezone.utc)
    start_time = end_time - datetime.timedelta(days=days)

    print(f"Fetching events from {start_time} to {end_time} for instance {instance_id}")

    s3_event_names = [
        'GetObject', 'PutObject', 'ListBucket', 'CreateBucket', 'DeleteBucket', 'HeadBucket'
    ]

    s3_buckets = set()
    next_token = None

    while True:
        if next_token:
            response = client.lookup_events(
                LookupAttributes=[
                    {
                        'AttributeKey': 'Username',
                        'AttributeValue': instance_id
                    },
                ],
                StartTime=start_time,
                EndTime=end_time,
                MaxResults=50,
                NextToken=next_token
            )
        else:
            response = client.lookup_events(
                LookupAttributes=[
                    {
                        'AttributeKey': 'Username',
                        'AttributeValue': instance_id
                    },
                ],
                StartTime=start_time,
                EndTime=end_time,
                MaxResults=50
            )

        events = response['Events']
        print(f"Found {len(events)} events")

        for event in events:
            print(f"Event: {event['EventName']}, Source: {event['EventSource']}, User: {event['Username']}, Time: {event['EventTime']}")
            if event['EventSource'] == 's3.amazonaws.com' and event['EventName'] in s3_event_names:
                print(f"Found S3 event: {event['EventName']} at {event['EventTime']}")
                for resource in event.get('Resources', []):
                    if resource['ResourceType'] == 'AWS::S3::Bucket':
                        s3_buckets.add(resource['ResourceName'])
                        print(f"Bucket accessed: {resource['ResourceName']}")

        next_token = response.get('NextToken')
        if not next_token:
            break

    return s3_buckets

def main():
    instance_id = 'i-0bcb2826cb0019396'
    days = 2  # Define the number of days for the report
    s3_buckets = get_s3_accessed_buckets(instance_id, days)

    if not s3_buckets:
        print(f"No S3 buckets accessed by instance {instance_id} in the past {days} days.")
        return

    # Create a CSV report
    report_file = 's3_accessed_buckets_report.csv'
    with open(report_file, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['S3BucketName'])
        for bucket in s3_buckets:
            writer.writerow([bucket])

    print(f'Report generated: {report_file}')

if __name__ == '__main__':
    main()
