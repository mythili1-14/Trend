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
        stage('Build & Push Docker Image') {
            steps {
                script {
                    def dockerImage = docker.build("mythili121/trend-app:${env.BUILD_NUMBER}", ".")
                    
                    // The withRegistry block handles Docker login and logout automatically.
                    withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS_ID, passwordVariable: 'DOCKERHUB_TOKEN', usernameVariable: 'DOCKERHUB_USER')]) {
                         docker.withRegistry('https://registry.hub.docker.com', DOCKERHUB_CREDENTIALS_ID) {
                            dockerImage.push()
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
