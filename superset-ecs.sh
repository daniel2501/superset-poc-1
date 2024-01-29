#!/usr/bin/env sh

# Pull the official docker image
docker pull apache/superset
# Install AWS CLI and Session Manager plugin
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
# Install ECR CLI
sudo curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli
echo $PATH | grep /usr/local/bin
ecs-cli --version
# Set AWS credentials
export AWS_ACCESS_KEY_ID=*********************
export AWS_SECRET_ACCESS_KEY=*********************************
export AWS_DEFAULT_REGION=us-east-1
# Clone the docker image from the official repo
git clone https://github.com/apache/superset.git
cd superset
# Replace image name with our ECR image
sed -i 's/*superset-image/128862924679.dkr.ecr.us-east-1.amazonaws.com\/superset-poc-1:latest/g' docker-compose-non-dev.yml
# Create a key pair
aws ec2 create-key-pair --key-name superset-poc-kp | jq -r '[."KeyMaterial",."KeyName"]|join("\t")' | xargs -d "\t" sh -c 'echo "$0" > $HOME/.ssh/$(echo -n "$1").pem;';
# Provision EC2 instance to host containers
ecs-cli up --cluster superset-poc-cluster-1 \
           --keypair superset-poc-kp \
           --capability-iam \
           --instance-type m5.xlarge \
           --port 8080 \
           --port 8088 \
           --launch-type EC2
# Create ECS task definition
ecs-cli compose -f $HOME/repos/superset/docker-compose-non-dev.yml create
# --cluster superset-poc-cluster-1
# Start the task
ecs-cli compose -f $HOME/repos/superset/docker-compose-non-dev.yml start
