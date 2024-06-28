import json
import sys
import boto3

region = sys.argv[1]

ssm_client = boto3.client('ssm', region)

copied_parameters = []

paginator = ssm_client.get_paginator('describe_parameters')
page_iterator = paginator.paginate(
    PaginationConfig={
        'PageSize': 50
    }
)

for page in page_iterator:
    Parameters = page['Parameters']
    for parameter in Parameters:
        try:
            if parameter['Name'].startswith('/motionmd/config/flux/'):
                Name = parameter['Name'].replace('/motionmd/config/flux/', '/motionmd/config/acceptance/')
                Type = parameter['Type']
                Description = parameter.get('Description', '')
                Tier = parameter['Tier']
                ssm_get_response = ssm_client.get_parameter(
                    Name=parameter['Name'],
                    WithDecryption=True
                )
                Value = ssm_get_response['Parameter']['Value']

                ssm_put_response = ssm_client.put_parameter(
                    Name=Name,
                    Description=Description,
                    Value=Value,
                    Type=Type,
                    Tier=Tier,
                    Overwrite=False
                )
                copied_parameters.append(Name)
                print(f'Parameter {Name} has been copied and renamed')
        except Exception as e:
            print(f'Error copying parameter {parameter["Name"]}: {str(e)}')
            input('Press Enter to Continue...')

print(f'\nCopied and renamed {len(copied_parameters)} parameters:')
for parameter in copied_parameters:
    print(parameter)
