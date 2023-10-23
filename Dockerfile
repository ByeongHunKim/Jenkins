FROM jenkins/jenkins:2.401.3

USER root

# AWS CLI
RUN curl "https://d1vvhvl2y92vvt.cloudfront.net/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install

# Docker CLI
RUN apt-get update \
    && apt-get install -y docker.io

# Docker Buildx
RUN docker buildx create --use --platform=linux/arm64,linux/amd64 --name multi-platform-builder

USER jenkins
