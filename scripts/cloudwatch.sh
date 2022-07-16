#!/bin/bash

cd ~
curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/AgentDependencies.tar.gz -O
tar xvf AgentDependencies.tar.gz -C /tmp/

sudo python ./awslogs-agent-setup.py --region us-east-1 --dependency-path /tmp/AgentDependencies
sudo python ./awslogs-agent-setup.py -c test.txt -n -r us-east-1 --dependency-path /tmp/AgentDependencies
sudo service awslogs restart
