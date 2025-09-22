pipeline {
    agent any
    
    tools {
        docker 'docker' 
        git 'Default'
    }

    environment {
        // This variable holds the ID of your DockerHub credentials in Jenkins.
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        // This variable holds the ID of your kubeconfig credentials.
        KUBECONFIG_CREDENTIALS_ID = 'eks-cluster-credentials'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/YourUsername/Trend.git'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    sh 'docker build -t mythili121/trend-app:${env.BUILD_NUMBER} .'
                    
                    // The withCredentials block makes the username and password available as environment variables.
                    withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS_ID, passwordVariable: 'DOCKERHUB_TOKEN', usernameVariable: 'DOCKERHUB_USER')]) {
                        sh 'echo ${DOCKERHUB_TOKEN} | docker login --username ${DOCKERHUB_USER} --password-stdin'
                        sh 'docker push mythili121/trend-app:${env.BUILD_NUMBER}'
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh "sed -i 's|image: .*|image: mythili121/trend-app:${env.BUILD_NUMBER}|g' kubernetes/deployment.yaml"
                    
                    // The withKubeConfig block uses the secret file to set up the kubeconfig.
                    withKubeConfig([credentialsId: KUBECONFIG_CREDENTIALS_ID]) {
                        sh 'kubectl apply -f kubernetes/'
                    }
                }
            }
        }
    }
}
