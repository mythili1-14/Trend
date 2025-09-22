# Application Deployment with Docker, Terraform, Jenkins, and Kubernetes

This project details the end-to-end deployment of a simple React application to a production-ready state on AWS. The solution utilizes a modern CI/CD pipeline built with Docker, Terraform, Jenkins, and Kubernetes.

##  Repository Structure

The project repository contains all the necessary files for a full CI/CD pipeline.

  - `dist/`: The pre-built static assets of the React application.
  - `Dockerfile`: Defines the container image for the application.
  - `Jenkinsfile`: The declarative pipeline script for Jenkins.
  - `kubernetes/`:
      - `deployment.yaml`: The Kubernetes deployment manifest for the application.
      - `service.yaml`: The Kubernetes service manifest to expose the application via a Load Balancer.
  - `terraform/`:
      - `main.tf`: The Terraform configuration to provision all AWS infrastructure.
  - `.gitignore`: Specifies files to be ignored by Git.
  - `.dockerignore`: Specifies files to be excluded from the Docker build context.

-----

##  Deployment Architecture

The deployment process follows a standard CI/CD workflow:

1.  **Version Control (Git):** The application code, Dockerfile, Jenkinsfile, and Kubernetes manifests are all managed in a Git repository.
2.  **Infrastructure as Code (Terraform):** Terraform is used to provision all required AWS resources, including a VPC, an EKS cluster, and a Jenkins server on an EC2 instance.
3.  **Containerization (Docker):** The React application's static assets are packaged into a lightweight Docker image using a multi-stage `Dockerfile`.
4.  **Continuous Integration (Jenkins):** Jenkins is configured with a pipeline that:
      - Pulls the latest code from GitHub via a webhook trigger.
      - Builds the Docker image from the pre-compiled `dist` folder.
      - Pushes the tagged image to DockerHub.
5.  **Continuous Deployment (Kubernetes):** Jenkins applies the Kubernetes manifests to the AWS EKS cluster, deploying the new Docker image and updating the application without downtime.
6.  **Monitoring (Prometheus & Grafana):** An open-source monitoring stack is deployed to check the health and performance of the EKS cluster and the application.

-----

## 🛠️ Setup Instructions

Follow these steps to set up the entire environment from scratch.

### 1\. **Initial Setup**

  - **Clone the Repository:**
    ```bash
    git clone https://github.com/mythili1-14/Trend.git
    cd Trend
    ```
  - **Configure Git:** Set up your user name and email, and push the codebase to your own GitHub repository.
    ```bash
    git init
    git add .
    git commit -m "Initial project setup"
    git remote add origin https://github.com/YourUsername/YourRepo.git
    git push -u origin main
    ```

### 2\. **Terraform & AWS Infrastructure**

  - **Create Terraform Configuration:** The `terraform/main.tf` file defines all the necessary AWS infrastructure.
  - **Provision Infrastructure:** Run the following commands to create the VPC, EKS cluster, and Jenkins EC2 instance.
    ```bash
    cd terraform
    terraform init
    terraform apply --auto-approve
    ```
  - **Get Jenkins Public IP:** The `terraform apply` command will output the public IP of the Jenkins server.

### 3\. **Jenkins Configuration**

  - **Access Jenkins:** Open a browser and navigate to `http://<jenkins_public_ip>:8080`.
  - **Retrieve Admin Password:** SSH into the Jenkins EC2 instance to get the initial admin password.
    ```bash
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    ```
  - **Install Plugins:** Install the required plugins: `Docker Pipeline`, `Git`, `Kubernetes Pipeline`, and `Kubernetes CLI`.
  - **Add Credentials:** Go to **Manage Jenkins -\> Credentials** and add your DockerHub credentials (`dockerhub-credentials`) and your AWS `kubeconfig` as a secret file (`eks-cluster-credentials`).
  - **Create Pipeline Job:** Create a new **Pipeline** job, configure it to use Git, and point the script path to `Jenkinsfile`.
  - **Set up Webhook:** In your GitHub repository settings, create a webhook that points to your Jenkins server's GitHub webhook endpoint to trigger builds automatically on pushes.

### 4\. **Monitoring (Prometheus & Grafana)**

  - **Install Helm:** Install Helm on the Jenkins server.
  - **Deploy Monitoring Stack:** Use Helm to deploy Prometheus and Grafana to your EKS cluster.
    ```bash
    helm install prometheus prometheus-community/kube-prometheus-stack
    helm install grafana grafana/grafana
    ```
  - **Access Grafana:** Port-forward the Grafana service to your local machine and use the admin password from the Kubernetes secret to log in.

-----

##  Screenshots

### **1. Jenkins Pipeline Success**

<img src="https://github.com/mythili1-14/Trend/blob/main/screenshots/Screenshot_20250922_233448.png" alt="Banner" />

### **2. Deployed Application**

<img src="https://github.com/mythili1-14/Trend/blob/main/screenshots/Screenshot_20250923_000953.png" alt="Banner" />


### **3. Grafana Dashboard**

<img src="https://github.com/mythili1-14/Trend/blob/main/screenshots/Screenshot_20250923_002954.png" alt="Banner" />


<img src="https://github.com/mythili1-14/Trend/blob/main/screenshots/Screenshot_20250923_002740.png" alt="Banner" />



## More Screenshots at **Screenshots**


-----

##  Submission Artifacts

  - **GitHub Link:** [https://github.com/mythili1-14/Trend.git](https://github.com/mythili1-14/Trend.git)
  - **Application Deployed Kubernetes Load Balancer ARN:**
      - `arn:aws:elasticloadbalancing:us-east-1:551210489378:loadbalancer/net/a33e67da46f79448b9338a67f5302aa1/3b73ad892c548687`
