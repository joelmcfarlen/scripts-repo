import boto3
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

def get_unused_lambda_functions(region_name='us-east-1', days=90):
    # Create a boto3 client for Lambda and CloudWatch Logs service
    lambda_client = boto3.client('lambda', region_name=region_name)
    logs_client = boto3.client('logs', region_name=region_name)

    # Get a list of all Lambda functions
    functions = lambda_client.list_functions()['Functions']

    unused_functions = []

    # Calculate the date 90 days ago
    days_ago = datetime.now() - timedelta(days=days)

    # Iterate through each Lambda function
    for function in functions:
        function_name = function['FunctionName']

        try:
            # Get the log streams for the Lambda function
            log_streams = logs_client.describe_log_streams(
                logGroupName='/aws/lambda/' + function_name,
                orderBy='LastEventTime',
                descending=True
            )['logStreams']

            # If no log streams found, mark as unused
            if not log_streams:
                unused_functions.append(function_name)
                continue

            # Get the last log event time
            last_log_time = datetime.fromtimestamp(log_streams[0]['lastEventTimestamp'] / 1000)

            # Check if the function hasn't been invoked in the last 90 days
            if last_log_time < days_ago:
                unused_functions.append(function_name)

        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                unused_functions.append(function_name)

    return unused_functions

if __name__ == "__main__":
    unused_functions = get_unused_lambda_functions()

    if unused_functions:
        print("Unused Lambda functions found:")
        for function_name in unused_functions:
            print(function_name)
    else:
        print("No unused Lambda functions found.")
