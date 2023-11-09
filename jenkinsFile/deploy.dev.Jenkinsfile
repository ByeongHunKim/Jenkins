pipeline {
    agent any

    environment {
        // docker
        JENKINS_NETWORK=""
        JENKINS_CONTAINER=""

        // generate image tag shell script path
        GEN_IMAGE_TAG_FILE_PATH=''

        // ECR environment
        AWS_ACCOUNT_ID=""
        AWS_DEFAULT_REGION="ap-northeast-2" // seoul region
        ECR_REPOSITORY_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/"
        API_IMAGE_REPO_NAME=""
        NGINX_IMAGE_REPO_NAME=""

        // ECS environment
        CLUSTER_NAME= ''
        SERVICE_NAME= ''
        TASK_DEFINITION_PATH = ''

        // Slack environment
        SLACK_CHANNEL = ''

        // prisma
        PRISMA_POSTGRES_CONTAINER="temp-${JOB_NAME}-${BUILD_NUMBER}-postgres" // temp postgres db container name

        // secrets
        SECRETS_ID="" // aws secret manager
        DATABASE_URL_PATH="" // database url
    }

    stages {

        stage('Notify to start deploy') {
            steps {
                slackSend(
                    channel: SLACK_CHANNEL,
                    blocks: [[
                        type: 'section',
                        text: [
                            type: 'mrkdwn',
                            text: ":arrow_forward: ${env.JOB_BASE_NAME} pipeline started. Triggered by ${env.GITHUB_WEBHOOK_COMMIT_USER}\n(<${env.BUILD_URL}console | View pipeline>)",
                        ],
                    ]],
                )
            }
        }

        stage('Install dependencies') {
          steps {
            nodejs(nodeJSInstallationName: 'node-20.x') {
              sh """
              npm ci
              """
            }
          }
        }

        stage('Database Build') {
            steps {
                script {
                    sh """
                    docker run -d --name ${env.PRISMA_POSTGRES_CONTAINER} \
                        --network=${env.JENKINS_NETWORK} \
                        -e POSTGRES_DB=temp \
                        -e POSTGRES_USER=local \
                        -e POSTGRES_PASSWORD=local \
                        postgres:15.3
                    """
                }

                // for prisma generate-client task
                nodejs(nodeJSInstallationName: 'node-20.x') {
                    sh """
                    export DATABASE_URL="postgresql://local:local@${env.PRISMA_POSTGRES_CONTAINER}:5432/temp"
                    npm run db:migrate
                    """
                }
            }
        }


        stage('AWS ECR Login'){
            steps {
                script {
                    try {
                        sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
                    } catch (Exception e) {
                        slackSend(
                            channel: SLACK_CHANNEL,
                            blocks: [[
                                type: 'section',
                                text: [
                                    type: 'mrkdwn',
                                    text: ":warning: Error occurred in *AWS ECR Login* stage.\n`:warning:${e.getMessage()}`",
                                ],
                            ]],
                        )
                        throw e
                    }
                }
            }
        }

        stage('Set API Image Tag') {
            steps {
                script {
                    env.API_IMAGE_TAG = sh(script: "${GEN_IMAGE_TAG_FILE_PATH} ${API_IMAGE_REPO_NAME}", returnStdout: true).trim()
                    echo "Final api image tag is: ${env.API_IMAGE_TAG}"
                }
            }
        }

        stage('Set NGINX Image Tag') {
            steps {
                script {
                    env.NGINX_IMAGE_TAG = sh(script: "${GEN_IMAGE_TAG_FILE_PATH} ${NGINX_IMAGE_REPO_NAME}", returnStdout: true).trim()
                    echo "Final nginx image tag is: ${env.NGINX_IMAGE_TAG}"
                }
            }
        }

        stage('Nginx Docker Build') {
            steps {
                script {
                    try {
                        sh "docker buildx use jenkinsbuilder"
                        sh "docker buildx build --platform linux/amd64,linux/arm64 --push -t ${ECR_REPOSITORY_URI}${NGINX_IMAGE_REPO_NAME}:${env.NGINX_IMAGE_TAG} -f infra/docker/nginx/dev.Dockerfile infra/docker/nginx"
                    } catch (Exception e) {
                        slackSend(
                            channel: SLACK_CHANNEL,
                            blocks: [[
                                type: 'section',
                                text: [
                                    type: 'mrkdwn',
                                    text: ":warning: Error occurred in *Docker Build* stage.\n:warning:`${e.getMessage()}`",
                                ],
                            ]],
                        )
                        throw e
                    }
                }
            }
        }

        stage('API Docker Build') {
            steps {
                script {
                    try {
                      sh "docker buildx use jenkinsbuilder"
                      sh "docker buildx build --push --platform=linux/arm64,linux/amd64 -t ${ECR_REPOSITORY_URI}${API_IMAGE_REPO_NAME}:${env.API_IMAGE_TAG} -f infra/docker/app/Dockerfile . --progress plain"
                    } catch (Exception e) {
                        slackSend(
                            channel: SLACK_CHANNEL,
                            blocks: [[
                                type: 'section',
                                text: [
                                    type: 'mrkdwn',
                                    text: ":warning: Error occurred in *Docker Build* stage.\n:warning:`${e.getMessage()}`",
                                ],
                            ]],
                        )
                        throw e
                    }
                }
            }
        }

        stage('Migrate DB') {
          steps {
            script {
              nodejs(nodeJSInstallationName: 'node-20.x') {
                sh """
                DATABASE_URL=\$(aws secretsmanager get-secret-value --secret-id ${env.SECRETS_ID} | yq e '.SecretString' - | yq e '${env.DATABASE_URL_PATH}' -)
                export DATABASE_URL
                npm run db:migrate
                """
              }
            }
          }
        }

        stage('Modify Task Definition') {
            steps {
                script {
                    try {
                        def taskDefinition = readJSON file: env.TASK_DEFINITION_PATH

                        echo "Before task definition with nginx image: ${taskDefinition.containerDefinitions[0].image}"
                        echo "Before task definition with api image: ${taskDefinition.containerDefinitions[1].image}"

                        // Update the image tag in the task definition
                        taskDefinition.containerDefinitions[0].image = "${ECR_REPOSITORY_URI}${NGINX_IMAGE_REPO_NAME}:${env.NGINX_IMAGE_TAG}".toString()
                        taskDefinition.containerDefinitions[1].image = "${ECR_REPOSITORY_URI}${API_IMAGE_REPO_NAME}:${env.API_IMAGE_TAG}".toString()

                        // Write the modified task definition back to the file
                        writeJSON file: env.TASK_DEFINITION_PATH, json: taskDefinition

                        echo "After task definition with nginx image: ${taskDefinition.containerDefinitions[0].image}"
                        echo "After updated task definition with api image: ${taskDefinition.containerDefinitions[1].image}"
                    } catch (Exception e) {
                        slackSend(
                            channel: SLACK_CHANNEL,
                            blocks: [[
                                type: 'section',
                                text: [
                                    type: 'mrkdwn',
                                    text: ":warning: Error occurred in *Modify Task Definition* stage.:warning:`${e.getMessage()}`",
                                ],
                            ]],
                        )
                        throw e
                    }
                }
            }
        }

        stage('Register Task Definition') {
            steps {
                script {
                    try {
                        def registerOutput = sh(script: "aws ecs register-task-definition --cli-input-json file://${env.TASK_DEFINITION_PATH}", returnStdout: true).trim()

                        def registerOutputJson = readJSON(text: registerOutput)

                        env.NEW_TASK_DEFINITION_ARN = registerOutputJson.taskDefinition.taskDefinitionArn

                        echo "Registered new task definition with ARN: ${env.NEW_TASK_DEFINITION_ARN}"
                    } catch (Exception e) {
                        slackSend(
                            channel: SLACK_CHANNEL,
                            blocks: [[
                                type: 'section',
                                text: [
                                    type: 'mrkdwn',
                                    text: ":warning: Error occurred in *Register Task Definition* stage.\n:warning:`${e.getMessage()}`",
                                ],
                            ]],
                        )
                        throw e
                    }
                }
            }
        }

        stage('Update ECS Service for deploy') {
            steps {
                script {
                    try {
                        sh "aws ecs update-service --cluster ${CLUSTER_NAME} --service ${SERVICE_NAME} --task-definition ${env.NEW_TASK_DEFINITION_ARN} --force-new-deployment"
                    } catch (Exception e) {
                        slackSend(
                            channel: SLACK_CHANNEL,
                            blocks: [[
                                type: 'section',
                                text: [
                                    type: 'mrkdwn',
                                    text: ":warning: Error occurred in *Update ECS Service for deploy* stage.\n:warning:`${e.getMessage()}`",
                                ],
                            ]],
                        )
                        throw e
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend(
                channel: SLACK_CHANNEL,
                blocks: [[
                    type: 'section',
                    text: [
                        type: 'mrkdwn',
                        text: ":white_check_mark: ${env.JOB_BASE_NAME} pipeline succeed. Triggered by ${env.GITHUB_WEBHOOK_COMMIT_USER}\n(<${env.BUILD_URL}console | View pipeline>)",
                    ],
                ]],
            )
        }

        failure {
            slackSend(
                channel: SLACK_CHANNEL,
                blocks: [[
                    type: 'section',
                    text: [
                        type: 'mrkdwn',
                        text: ":x: ${env.JOB_BASE_NAME} pipeline failed. Triggered by ${env.GITHUB_WEBHOOK_COMMIT_USER}\n(<${env.BUILD_URL}console | View pipeline>)",
                    ],
                ]],
            )
        }
    }
}
