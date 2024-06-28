import boto3
from openpyxl import Workbook

def get_expensive_volumes(ec2_client, ce_client, threshold_price):
    expensive_volumes = []

    # Retrieve all EBS volumes
    response = ec2_client.describe_volumes()

    # Check each volume for cost
    for volume in response['Volumes']:
        volume_id = volume['VolumeId']

        # Get the volume's associated tags to find the 'Name' tag
        tags = ec2_client.describe_tags(Filters=[{'Name': 'resource-id', 'Values': [volume_id]}])['Tags']
        volume_name = next((tag['Value'] for tag in tags if tag['Key'] == 'Name'), 'N/A')

        # Calculate the cost of the volume using AWS Cost Explorer API
        cost_response = ce_client.get_cost_and_usage(
            TimePeriod={'Start': '2024-01-01', 'End': '2024-01-31'},
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'],
            Filter={
                "Dimensions": {
                    "Key": "LINKED_ACCOUNT",
                    "Values": ["<Your AWS Account ID>"]
                },
                "Tags": {
                    "Key": "ResourceId",
                    "Values": [volume_id]
                }
            }
        )

        volume_cost = float(cost_response['ResultsByTime'][0]['Total']['UnblendedCost']['Amount'])

        # Check if the volume cost exceeds the threshold
        if volume_cost > threshold_price:
            expensive_volumes.append({'VolumeId': volume_id, 'Name': volume_name, 'Cost': volume_cost})

    return expensive_volumes

def write_to_excel(expensive_volumes):
    workbook = Workbook()
    sheet = workbook.active

    # Write header
    sheet.append(['VolumeId', 'Name', 'Cost'])

    # Write data
    for volume in expensive_volumes:
        sheet.append([volume['VolumeId'], volume['Name'], volume['Cost']])

    # Save the workbook to a file
    workbook.save('expensive_volumes.xlsx')

def main():
    # Set your AWS region
    region = 'us-east-1'

    # Set the threshold price in USD
    threshold_price = 10.0

    # Create EC2 and Cost Explorer clients
    ec2_client = boto3.client('ec2', region_name=region)
    ce_client = boto3.client('ce', region_name=region)

    # Get expensive volumes
    expensive_volumes = get_expensive_volumes(ec2_client, ce_client, threshold_price)

    if expensive_volumes:
        print("Expensive EBS Volumes:")
        for volume in expensive_volumes:
            print(f"VolumeId: {volume['VolumeId']}, Name: {volume['Name']}, Cost: ${volume['Cost']:.2f}")

        # Write results to Excel spreadsheet
        write_to_excel(expensive_volumes)
        print("Results written to 'expensive_volumes.xlsx'")
    else:
        print("No expensive EBS volumes found.")

if __name__ == "__main__":
    main()
