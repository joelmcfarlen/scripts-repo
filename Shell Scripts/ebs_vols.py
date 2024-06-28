import boto3
import csv

def list_unattached_volumes():
    # Create EC2 client
    ec2 = boto3.client('ec2')

    # Get current region
    current_region = ec2.meta.region_name

    # Get current account ID
    current_account_id = boto3.client('sts').get_caller_identity().get('Account')

    # Get all volumes
    response = ec2.describe_volumes()

    # Filter unattached volumes with 'available' state
    unattached_volumes = []
    for volume in response['Volumes']:
        if volume['State'] == 'available':
            unattached_volumes.append(volume)

    return current_region, current_account_id, unattached_volumes

def get_volume_tags(ec2, volume_id):
    tags = ec2.describe_tags(Filters=[{'Name': 'resource-id', 'Values': [volume_id]}])['Tags']
    return {tag['Key']: tag['Value'] for tag in tags}

def write_to_csv(region, account_id, volumes):
    with open('unattached_volumes.csv', mode='w', newline='') as csv_file:
        fieldnames = ['Account ID', 'Region', 'Volume ID', 'Name', 'Size', 'Creation Date', 'Available State', 'Tags']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)

        writer.writeheader()
        for volume in volumes:
            volume_id = volume['VolumeId']
            creation_date = volume['CreateTime'].strftime("%Y-%m-%d %H:%M:%S")
            size = volume['Size']
            name = volume.get('Tags', [{}])[0].get('Value', '')
            tags = get_volume_tags(boto3.client('ec2', region_name=region), volume_id)
            writer.writerow({'Account ID': account_id, 'Region': region, 'Volume ID': volume_id, 'Name': name, 'Size': size, 'Creation Date': creation_date, 'Available State': 'available', 'Tags': tags})

def main():
    region, account_id, unattached_volumes = list_unattached_volumes()

    if unattached_volumes:
        write_to_csv(region, account_id, unattached_volumes)
        print("CSV file 'unattached_volumes.csv' created successfully.")
    else:
        print("No unattached volumes found.")

if __name__ == "__main__":
    main()
