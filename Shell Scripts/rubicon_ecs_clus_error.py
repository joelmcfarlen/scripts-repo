import boto3
import json
import csv
from datetime import datetime, timedelta

# Initialize boto3 client for CloudWatch Logs
client = boto3.client('logs')

# Calculate the start time (3 months ago)
start_time = int((datetime.now() - timedelta(days=90)).timestamp() * 1000)  # Approximately 3 months

# Function to search for specified log events in a log group
def search_log_group(log_group_name, filter_pattern):
    paginator = client.get_paginator('filter_log_events')
    response_iterator = paginator.paginate(
        logGroupName=log_group_name,
        startTime=start_time,
        filterPattern=filter_pattern
    )
    
    matching_logs = []
    
    for response in response_iterator:
        for event in response['events']:
            message = event['message']
            try:
                log_data = json.loads(message)
                matching_log = {
                    'timestamp': event['timestamp'],
                    'Cluster Name': log_data.get('Cluster Name', 'N/A'),
                    'Task Arn': log_data.get('Task Arn', 'N/A'),
                    'Task Definition': log_data.get('Task Definition', 'N/A'),
                    'Container Name': log_data.get('Container Name', 'N/A')
                }
                matching_logs.append(matching_log)
            except json.JSONDecodeError:
                continue

    return matching_logs

# Function to write logs to CSV file
def write_logs_to_csv(logs, filename):
    keys = ['timestamp', 'Cluster Name', 'Task Arn', 'Task Definition', 'Container Name']
    with open(filename, 'w', newline='') as output_file:
        dict_writer = csv.DictWriter(output_file, fieldnames=keys)
        dict_writer.writeheader()
        dict_writer.writerows(logs)

# Main function to initiate search and write to CSV
def main():
    log_group_name = '/aws/lambda/ECSFailedLaunchNotifier'  # Replace with your log group name
    filter_pattern = '"Message content being sent to Teams"'  # Filter pattern for the log events
    matching_logs = search_log_group(log_group_name, filter_pattern)
    
    if matching_logs:
        csv_filename = 'matching_logs.csv'
        write_logs_to_csv(matching_logs, csv_filename)
        print(f"Matching logs have been written to {csv_filename}")
    else:
        print("No matching logs found.")

if __name__ == "__main__":
    main()
