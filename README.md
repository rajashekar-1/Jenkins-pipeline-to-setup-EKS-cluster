# Jenkins-pipeline-to-setup-EKS-cluster
A simple yet dynamic Jenkins pipeline to setup a EKS cluster on AWS with terraform configuration files.


## Setup a ec2 instance ( UBUNTU ) and install Jenkins and Terraform.
Create an IAM role with, 
  Trusted entity = EC2  
  Permission = Admin  

Launch an ec2 instance and attach this role to the instance.  
  
NOTE: The cluster need permission to launch instances, assign roles, node gorup and hence needs respective permission, So gave an admin permission. We can fine grade the permission upto what is necessary if requied.  
  
Jenkins, 
```
vi jenkins.sh
```
```
#!/bin/bash
sudo apt update -y
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
sudo apt update -y
sudo apt install temurin-17-jdk -y
/usr/bin/java --version
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y
sudo systemctl start jenkins
```

Terraform, Kubectl, AWS CLI
```
vi script.sh
```
```
#!/bin/bash
#install terraform
sudo apt install wget -y
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

#install Kubectl on Jenkins
sudo apt update
sudo apt install curl -y
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

#install Aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install unzip -y
unzip awscliv2.zip
sudo ./aws/install
```
  
Run the script to setup.  
Login to Jenkins UI.    
  
Install terraform plugin and restart, 
`manage Jenkins --> plugins ---> available plugins ---> terraform.`  

Setup the terraform in the tools section of Jenkins,
`Manage Jenkins –> Tools ---> Terraform.`  
  
Set the values,   
`Name = Terraform`  
`Uncheck the install automatically`,  
`intall dir = /usr/bin`  

Note: the install directory is the directory where our terraform was installed in the ec2 instance, we can verify using the command `which terraform` on the ec2 instance.


## Jenkins pipeline

1. Create a s3 bucket in the AWS console, and set the same name for the bucket in `backend.tf` file of terrafrom.
2. Pipeline,

`Jenkins Dashboard ---> New Item/JOb --> Pipeline --> Name = EKSJOB`, 
  
This project is parameterized
`Name: action`
choices:   
 apply  
 destroy  


```
pipeline{
    agent any
    stages {
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/AreParameswarudu/Jenkins-pipeline-to-setup-EKS-cluster'
            }
        }
        stage('Terraform version'){
             steps{
                 sh 'terraform --version'
             }
        }
        stage('Terraform init'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform init'
                   }
             }
        }
        stage('Terraform validate'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform validate'
                   }
             }
        }
        stage('Terraform plan'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform plan'
                   }
             }
        }
        stage('Terraform apply/destroy'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform ${action} --auto-approve'
                   }
             }
        }
    }
}
```

Save and build the pipeline.
`Build with parameter ---> action = apply`   ---> to setup the cluster.  
`Build with parameter ---> action  = destroy`  ---> to destroy the cluster.
