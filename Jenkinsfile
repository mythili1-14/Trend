pipeline {
    agent any
    
    tools {
        dockerTool 'docker' 
        git 'Default'
    }

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        KUBECONFIG_CREDENTIALS_ID = 'eks-cluster-credentials'
    }

    stages {
        // Remove the manual "Clone Repository" stage. Jenkins already does this.

        stage('Build & Push Docker Image') {
            steps {
                script {
                    sh 'docker build -t mythili121/trend-app:${env.BUILD_NUMBER} .'
                    
                    withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS_ID, passwordVariable: 'DOCKERHUB_TOKEN', usernameVariable: 'DOCKERHUB_USER')]) {
                     sh "echo ${env.DOCKERHUB_TOKEN} | docker login --username ${env.DOCKERHUB_USER} --password-stdin"
                     sh "docker push mythili121/trend-app:${env.BUILD_NUMBER}"
                       }
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh "sed -i 's|image: .*|image: mythili121/trend-app:${env.BUILD_NUMBER}|g' kubernetes/deployment.yaml"
                    
                    withKubeConfig([credentialsId: KUBECONFIG_CREDENTIALS_ID]) {
                        sh 'kubectl apply -f kubernetes/'
                    }
                }
            }
        }
    }
}
