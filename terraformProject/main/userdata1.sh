#!/bin/bash
set -e

echo "Updating system..."
apt update -y

# =====================================
# Install Base Packages
# =====================================
apt install -y \
  curl \
  unzip \
  gnupg2 \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  lsb-release \
  python3 \
  python3-pip

# =====================================
# Install Ansible (Latest Stable)
# =====================================
pip3 install --upgrade pip
pip3 install ansible

# Install AWS Ansible Collection
ansible-galaxy collection install amazon.aws

# =====================================
# Install Docker
# =====================================
mkdir -p /etc/apt/keyrings
chmod 755 /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

# Add ubuntu & jenkins users to docker group
usermod -aG docker ubuntu

# =====================================
# Install AWS CLI v2
# =====================================
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install

# =====================================
# Install Java 17
# =====================================
apt install -y openjdk-17-jdk

# =====================================
# Install Jenkins
# =====================================
# =====================================
# Install Jenkins (Correct Way)
# =====================================

# Add new Jenkins key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | \
tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" | \
tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update & Install
apt update -y
apt install -y jenkins

systemctl enable jenkins
systemctl start jenkins


# Add Jenkins to docker group
usermod -aG docker jenkins
systemctl restart jenkins

# =====================================
# Install Python AWS Libraries
# =====================================
pip3 install boto3 botocore

echo "-----------------------------------"
echo "Installation completed successfully!"
echo "Get Jenkins password using:"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo "-----------------------------------"

