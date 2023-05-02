import boto3
import json
import os
import logging

ssm_client = boto3.client('ssm')
ec2_client = boto3.client('ec2')

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event):
    # Get the SNS message containing the tag key and value
    try:
        message = json.loads(event['Records'][0]['Sns']['Message'])
    except json.JSONDecodeError:
        logger.error('Error parsing SNS message: invalid JSON format')
        return
    tag_key = json.loads(message)['tag-key']
    tag_value = json.loads(message)['tag-value']

    # Get a list of EC2 instances that have the specified tag
    ec2_instance = boto3.client('ec2')
    response = ec2_instance.describe_instances(
        Filters=[
            {'Name': 'tag:' + tag_key, 'Values': [tag_value]}
        ]
    )
    instance_ids = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])

    # Run the SSM Document on the instances that match the specified tag
    ssm_document = boto3.client('ssm')
    document_hash = os.environ['SSM_DOCUMENT_HASH']
    response = ssm_document.send_command(
        InstanceIds=instance_ids,
        DocumentName='AWS-RunDocument',
        DocumentVersion='latest',
        Parameters={'documentHashType': 'Sha256',
                    'documentHash': document_hash}
    )

    # Print the command ID returned by SSM
    print(response['Command']['CommandId'])
