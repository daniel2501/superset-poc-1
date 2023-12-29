#!/usr/bin/env sh

docker pull apache/superset
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
ar x session-manager-plugin.deb
tar xfvz data.tar.gz
cp usr/local/sessionmanagerplugin/bin/session-manager-plugin ~/bin
rm *.gz
rm -rf etc lib usr
rm session-manager-plugin.deb
rm debian-binary
source ~/.zshrc
export AWS_ACCESS_KEY_ID=*********************
export AWS_SECRET_ACCESS_KEY=*********************************
export AWS_DEFAULT_REGION=us-east-1
aws ecr create-repository \
    --repository-name superset-poc-1
aws ecr get-login-password
aws ecr | docker login -u AWS -p $(aws ecr get-login-password) \
    128862924679.dkr.ecr.us-east-1.amazonaws.com/superset-poc-1
aws ecs register-task-definition \
    --cli-input-json file://$HOME/repos/superset-oc-1/task-definition.json
aws ecs create-service --cluster superset-poc-cluster-1 \
    --service-name superset-poc-service-1 \
    --task-definition superset-ci:6 --desired-count 1 \
    --launch-type "FARGATE" \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-0dd76b52],securityGroups=[sg-39833e09], assignPublicIp=ENABLED}" \
    --enable-execute-command
aws iam create-role --role-name ecsTaskExecutionRole \
    --assume-role-policy-document file://ecs-tasks-trust-policy.json
aws ecs run-task --cluster arn:aws:ecs:us-east-1:128862924679:cluster/superset-poc-cluster-1 \
    --task-definition arn:aws:ecs:us-east-1:128862924679:task-definition/superset-ci:7 \
    --launch-type FARGATE --count 1 \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-0dd76b52],securityGroups=[sg-39833e09], assignPublicIp=ENABLED}"
