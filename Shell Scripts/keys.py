import sys
print(sys.executable)
  

import boto3
from datetime import datetime, timedelta, timezone
import csv

def get_key_age(key_creation_date):
    current_date = datetime.now(timezone.utc)
    key_age = current_date - key_creation_date
    return key_age.days

def get_last_used(key_id, iam):
    response = iam.get_access_key_last_used(AccessKeyId=key_id)
    last_used = response.get('AccessKeyLastUsed', {}).get('LastUsedDate')
    return last_used

def generate_csv_report(keys_data):
    with open('iam_keys_report.csv', mode='w', newline='') as file:
        fieldnames = ['User', 'AccessKeyId', 'CreationDate', 'KeyAge', 'LastUsed']
        writer = csv.DictWriter(file, fieldnames=fieldnames)

        writer.writeheader()
        for key_data in keys_data:
            writer.writerow({
                'User': key_data['user'],
                'AccessKeyId': key_data['access_key_id'],
                'CreationDate': key_data['creation_date'],
                'KeyAge': key_data['key_age'],
                'LastUsed': key_data['last_used']
            })

def main():
    iam = boto3.client('iam')

    # Get a list of all IAM users
    users = iam.list_users()['Users']

    keys_data = []

    for user in users:
        user_name = user['UserName']
        access_keys = iam.list_access_keys(UserName=user_name)['AccessKeyMetadata']
        
        for key in access_keys:
            access_key_id = key['AccessKeyId']
            creation_date = key['CreateDate']
            key_age = get_key_age(creation_date)
            last_used = get_last_used(access_key_id, iam)
            
            if key_age > 90:
                last_used_str = last_used.strftime("%Y-%m-%d %H:%M:%S %Z") if last_used else 'Never Used'
                keys_data.append({
                    'user': user_name,
                    'access_key_id': access_key_id,
                    'creation_date': creation_date.strftime("%Y-%m-%d"),
                    'key_age': key_age,
                    'last_used': last_used_str
                })

    generate_csv_report(keys_data)

if __name__ == "__main__":
    main()
