#!/bin/bash

# Update system
apt update -y
apt upgrade -y

# ===============================
# Install Required Packages
# ===============================
apt install -y curl unzip gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release

# ===============================
# Install Docker (Official Repo)
# ===============================

# Add Docker GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y

# Install Docker
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# ===============================
# Install AWS CLI v2
# ===============================

cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Verify
aws --version

# ===============================
# Install Java 17 (Required for Jenkins)
# ===============================
apt install -y openjdk-17-jdk

# ===============================
# Install Jenkins
# ===============================

# Add Jenkins GPG key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

apt update -y
apt install -y jenkins

# Start and enable Jenkins
systemctl start jenkins
systemctl enable jenkins

echo "Docker, AWS CLI, and Jenkins installation completed successfully!"
