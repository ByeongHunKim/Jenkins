FROM jenkins/jenkins:2.401.3

USER root
# packages
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
RUN mkdir -p ~/.docker/cli-plugins && \
    curl -SL https://github.com/docker/buildx/releases/download/v0.7.1/buildx-v0.7.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx && \
    chmod +x ~/.docker/cli-plugins/docker-buildx

# enable for using buildx
ENV DOCKER_CLI_EXPERIMENTAL=enabled

