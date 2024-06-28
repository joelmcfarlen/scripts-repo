import boto3
import datetime
import csv

def get_iam_role_api_calls(role_name, days=2):
    client = boto3.client('cloudtrail')
    end_time = datetime.datetime.now(datetime.timezone.utc)
    start_time = end_time - datetime.timedelta(days=days)

    print(f"Fetching events from {start_time} to {end_time} for role {role_name}")

    response = client.lookup_events(
        LookupAttributes=[
            {
                'AttributeKey': 'Username',
                'AttributeValue': role_name
            },
        ],
        StartTime=start_time,
        EndTime=end_time,
        MaxResults=50
    )

    events = response['Events']
    api_calls = []

    for event in events:
        event_time = event['EventTime']
        event_name = event['EventName']
        event_source = event['EventSource']
        user_identity = event['Username']
        request_parameters = event.get('RequestParameters', {})
        api_calls.append({
            'EventTime': event_time,
            'EventName': event_name,
            'EventSource': event_source,
            'UserIdentity': user_identity,
            'RequestParameters': request_parameters
        })

    while 'NextToken' in response:
        response = client.lookup_events(
            LookupAttributes=[
                {
                    'AttributeKey': 'Username',
                    'AttributeValue': role_name
                },
            ],
            StartTime=start_time,
            EndTime=end_time,
            MaxResults=50,
            NextToken=response['NextToken']
        )
        events = response['Events']
        for event in events:
            event_time = event['EventTime']
            event_name = event['EventName']
            event_source = event['EventSource']
            user_identity = event['Username']
            request_parameters = event.get('RequestParameters', {})
            api_calls.append({
                'EventTime': event_time,
                'EventName': event_name,
                'EventSource': event_source,
                'UserIdentity': user_identity,
                'RequestParameters': request_parameters
            })

    return api_calls

def main():
    role_name = 'djo-motionmd-prod-app-iam-role-IamRole-WGGT640CXU05'
    api_calls = get_iam_role_api_calls(role_name)

    if not api_calls:
        print(f"No API calls found for role {role_name} in the past 2 days.")
        return

    # Create a CSV report
    report_file = 'api_calls_report.csv'
    with open(report_file, mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=['EventTime', 'EventName', 'EventSource', 'UserIdentity', 'RequestParameters'])
        writer.writeheader()
        for call in api_calls:
            writer.writerow(call)

    print(f'Report generated: {report_file}')

if __name__ == '__main__':
    main()
