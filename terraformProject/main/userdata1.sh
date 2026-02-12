#!/bin/bash
set -e

# Update system
apt update -y && apt upgrade -y

# Install required packages
apt install -y curl unzip gnupg2 software-properties-common \
apt-transport-https ca-certificates lsb-release \
python3 python3-pip ansible

# ===============================
# Install Docker
# ===============================

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io \
docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# ===============================
# Install AWS CLI v2
# ===============================

cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install

# ===============================
# Install Java 17
# ===============================

apt install -y openjdk-17-jdk

# ===============================
# Install Jenkins
# ===============================

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/ | \
tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt update -y
apt install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# ===============================
# Python AWS Libraries
# ===============================

pip3 install boto3 botocore
ansible-galaxy collection install amazon.aws

echo "Installation completed successfully!"
echo "Get Jenkins password using:"
echo "cat /var/lib/jenkins/secrets/initialAdminPassword"

