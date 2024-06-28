import boto3
import csv
import os

# Create a session using your AWS credentials
s3 = boto3.client('s3')

# List all buckets
buckets_response = s3.list_buckets()

# Parameters for splitting files
max_rows_per_file = 1000000  # Adjust this value as needed
file_index = 1
row_count = 0

# Open the first CSV file for writing
file = open(f's3_objects_{file_index}.csv', mode='w', newline='')
writer = csv.writer(file)
# Write the header
writer.writerow(['BucketName', 'ObjectKey', 'Size', 'LastModified'])

# Iterate over each bucket and list objects
for bucket in buckets_response['Buckets']:
    bucket_name = bucket['Name']
    # Exclude buckets that start with "stackset-" and the specific bucket "djo-data-cloudtrail"
    if not bucket_name.startswith('stackset-') and bucket_name != 'djo-data-cloudtrail':
        print(f'Listing objects in bucket: {bucket_name}')
        
        # Pagination support for listing objects in a bucket
        paginator = s3.get_paginator('list_objects_v2')
        page_iterator = paginator.paginate(Bucket=bucket_name)

        for page in page_iterator:
            if 'Contents' in page:
                for obj in page['Contents']:
                    # Write object details to the CSV file
                    writer.writerow([bucket_name, obj['Key'], obj['Size'], obj['LastModified']])
                    row_count += 1
                    
                    # Check if the current file has reached the maximum row limit
                    if row_count >= max_rows_per_file:
                        file.close()
                        file_index += 1
                        row_count = 0
                        file = open(f's3_objects_{file_index}.csv', mode='w', newline='')
                        writer = csv.writer(file)
                        writer.writerow(['BucketName', 'ObjectKey', 'Size', 'LastModified'])

# Close the last file
file.close()

print('CSV files created successfully.')
