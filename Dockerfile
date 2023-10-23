FROM jenkins/jenkins:2.401.3

USER root
# 필요한 패키지 설치
RUN apt-get update && apt-get install -y unzip curl

RUN curl -sL https://github.com/mikefarah/yq/releases/download/v4.9.6/yq_linux_amd64 -o /usr/bin/yq && \
    chmod +x /usr/bin/yq

# AWS CLI
RUN curl "https://d1vvhvl2y92vvt.cloudfront.net/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Docker CLI
RUN apt-get install -y docker.io

# Docker Buildx
#RUN docker run --privileged --rm tonistiigi/binfmt --install all
#RUN docker buildx create --use --platform=linux/arm64,linux/amd64 --name multi-platform-builder && \
#    docker buildx inspect --bootstrap

