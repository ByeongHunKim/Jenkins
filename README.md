# Jenkins

## Jenkins Instance Setting
- `t3.medium`

```bash
sudo dnf install git -y
sudo dnf install docker -y
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo usermod -a -G docker ec2-user
sudo chown root:docker /var/run/docker.sock
docker ps -a

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version
```


## How to run
> Do not copy and paste. It might not always work 100% stable.
- `server_name jenkins.example.kr;`
  - `server_name` can be adjusted based on actual domain

### copy server.conf to ~/nginx/user_conf.d/server.conf
  ```
  mkdir -p ~/nginx/user_conf.d
  cp -av ./server.conf ~/nginx/user_conf.d/server.conf
  ```

### Push docker image to public repository
```bash
docker buildx build --platform=linux/arm64,linux/amd64 --push -t hunsman/jenkins-plus:[tag] .
# latest tag : v1.0.1
```


### run docker
  ```bash
  export PROJECT_NAME= 
  export MY_CERTBOT_EMAIL=
  docker-compose up -d
  ```

## Jenkins Setting

### 1. aws jenkins instance elastic IP setting

### 2. aws Route53 domain A record setting
- ip : elastic IP of jenkins instance

### 3. add PUBLIC-WEB-SERVICE sg into aws jenkins instance

### 4. docker-compose up -d
### 5. docker container log check
- docker logs -f container

### 6. access domain

### 7. login
- initail password is in jenkins container log 

### 8. suggested plugin

### 9. initial login status setting

### 10. add plugin
- Github Authentication Plugin
  - add member
- AWS Secrets Manager Credentioals Provider Plugin

- Slack Notification Plugin

- Generic Webhook Trigger Plugin

- Oracle Java SE Development Kit Plugin

- Command Agent Launcher

- Docker API

- Docker

- Docker CommonsVersion

- Docker Pipeline

- Publish Over SSH
