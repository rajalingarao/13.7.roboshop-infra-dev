# How to remove unnecessary files:
```
for d in 00-vpc/ 10-sg/ 20-bastion/ 30-rds/ 40-eks/ 50-acm/ 60-alb/ 70-ecr/ 80-cdn/; do
  echo "Removing from $d:"
  echo "  $d/.terraform"
  echo "  $d/.terraform.lock.hcl"

  rm -rf "$d/.terraform" "$d/.terraform.lock.hcl"

  echo "Deleted files from $d"
done
```
# Project consists of below components:
* 13.5.jenkins-shared-library-roboshop
* 13.6.roboshop-jenkins-cicd-tools
* 13.7.roboshop-infra-dev   
* MySQL is installed through 30-rds
* 13.9.roboshop-redis
* 13.8.roboshop-mongodb
* 13.9.roboshop-redis

* 13.11.roboshop-catalogue-CI
* 13.12.roboshop-catalogue-CD
* 13.13.roboshop-user-CI
* 13.14.roboshop-user-CD
* 13.15.roboshop-cart-CI
* 13.16.roboshop-cart-CD
* 13.17.roboshop-shipping-CI
* 13.18.roboshop-shipping-CD
* 13.19.roboshop-payment-CI
* 13.20.roboshop-payment-CD

* 13.21.roboshop-frontend
* 13.22.roboshop-dispatch
* 13.23.roboshop-debug

# Infrastructure creation and deletion
```
for i in 00-vpc/ 10-sg/ 20-bastion/ 30-rds/ 40-eks/ 50-acm/ 60-alb/ 70-ecr/ 80-cdn/ ; do cd $i; terraform init -reconfigure; cd .. ; done 
```
```
for i in  00-vpc/ 10-sg/ 20-bastion/ 30-rds/ 40-eks/ 50-acm/ 60-alb/ 70-ecr/ 80-cdn/  ; do cd $i; terraform plan; cd .. ; done 
```
```
for i in  00-vpc/ 10-sg/ 20-bastion/ 30-rds/ 40-eks/ 50-acm/ 60-alb/ 70-ecr/ 80-cdn/  ; do cd $i; terraform apply -auto-approve; cd .. ; done 
```
```
for i in  80-cdn/ 70-ecr/ 60-alb/ 50-acm/ 40-eks/ 30-rds/ 20-bastion/ 10-sg/ 00-vpc/  ; do cd $i; terraform destroy -auto-approve; cd .. ; done 
```

# Set Jenkins master and agent setup:
```
git clone https://github.com/rajalingarao/13.6.roboshop-jenkins-cicd-tools.git
```

```
cd 13.6.roboshop-jenkins-cicd-tools
```

```
terraform init -reconfigure
```

```
terraform plan
```

```
terraform apply -auto-approve
```

```
terraform destroy -auto-approve
```

# Jenkins
Install below plugins when you started Jenkins.

Plugins:
* Pipeline stage view
* Pipeline Utility Steps
* Rebuild
* Ansi Color
* Sonarqube Scanner

* AWS Credentials
```
withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
    // your AWS commands here
}
```

* AWS Steps --> This is not required using old plugin,

```
withAWS(region: 'us-east-1', credentials: "aws-creds-${environment}") {
    // your AWS CLI / terraform / kubectl steps
}
```

Restart Jenkins once plugins are installed
* Note: Jenkins Agent is used to run application and all services. Bastion server is used to troubleshoot or test entire application or database.

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

```
sudo yum install java-21-openjdk -y
java --version
sudo alternatives --config java   --> Select java 21 version
java --version
```

### Configure Agent
```
aws configure
```
* access key:
* secret access key:
* region:

```
aws s3 ls
```



### Configure Jenkins Shared Libraries in Jenkins master:
* Go to Manage Jenkins -> System
* Find Global Trusted Pipeline Libraries section
* Name as 'roboshop-jenkins-shared-library' , default version main and load implicitly
* Location is https://github.com/rajalingarao/13.5.jenkins-shared-library-roboshop.git
* Now Jenkins is ready to use.

# Infrastructure
Creating above infrastructure involves lot of steps, as maintained sequence we need to create
* VPC
* All security groups and rules
* Bastion Host, VPN
* EKS
* RDS
* ACM for ingress
* ALB as ingress controller
* ECR repo to host images
* CDN

## Sequence
* (Required). create VPC first
* (Required). create SG after VPC
* (Required). create bastion host. It is used to connect RDS and EKS cluster.
* (Optional). VPN, same as bastion but a windows laptop can directly connect to VPN and get access of RDS and EKS.
* (Required). RDS. Create RDS because we don't create databases in Kubernetes.
* (Required). ACM. It is required to get SSL certificates for our ALB ingress controller.
* (Required). ingress ALB is required to expose our applications to outside world.
* (Required). ECR. We need to create ECR repo to host the application images.
* (Optional). CDN is optional. but good to have.

### Admin activities
* Login into Bastion Server
* SSH to bastion host
* run below command and configure the credentials.

```
aws configure
```
* get the kubernetes config using below command
```
aws eks update-kubeconfig --region us-east-1 --name roboshop-dev
```
* Now you should be able to connect K8 cluster
```
kubectl get nodes
```
* Create a namespace
```
kubectl create namespace roboshop
```
# Roboshop DEV Infrastructure

![alt text](roboshop.svg)

* Make sure infra is created. 
* Every resource should have dev in its name, so that it will not overlap with prod resources.

Once infra is setup. We need to configure ingress controller to provide internet access to our expense application.

We are using Bastion as our EKS client, so it will have
* K9S
* kubectl
* helm
* aws configure

## RDS Configuration from Bastion server:
* Since we are using RDS instead of MySQL image, we need to configure RDS manually, we are creating schema as part of RDS but table and user should be created.
* Make sure MySQL instance allows port no 3306 from bastion

```
mysql -h roboshop-dev.c0d4soae2u8h.us-east-1.rds.amazonaws.com -u root -pRoboShop1
```

* Clone shipping component into bastion
```
git clone https://github.com/rajalingarao/13.17.roboshop-shipping-CI.git
```

* logout from mysql and Load the data into mysql on ec2-user.

```
mysql -h roboshop-dev.c0d4soae2u8h.us-east-1.rds.amazonaws.com -u root -pRoboShop1 < 13.17.roboshop-shipping-CI/db/schema.sql
```

```
mysql -h roboshop-dev.c0d4soae2u8h.us-east-1.rds.amazonaws.com -u root -pRoboShop1 < 13.17.roboshop-shipping-CI/db/app-user.sql
```

```
mysql -h roboshop-dev.c0d4soae2u8h.us-east-1.rds.amazonaws.com -u root -pRoboShop1 < 13.17.roboshop-shipping-CI/db/master-data.sql
```



## Target group binding
* If we are running frontend using normal user it can't bind the port 80. non root privelege user running container are not able to open system ports which are under 1024.
* So we have to use port no 8080 for frontend. Make sure
* nginx.conf opens port no 8080 instead of 80.
* ALB target group health check port should be 8080.
* frontend service target port should be 8080 instead of 80.

## Ingress Controller:

Ref: https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.8/
* Connect to K8 cluster from bastion host.
* Create an IAM OIDC provider. You can skip this step if you already have one for your cluster.

```
eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster roboshop-dev --approve
```

* Download an IAM policy for the LBC using one of the following commands:
```
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.2/docs/install/iam\_policy.json
```

* Create an IAM policy named AWSLoadBalancerControllerIAMPolicy. If you downloaded a different policy, replace iam-policy with the name of the policy that you downloaded.

```
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json
```

* (Optional) Use Existing Policy:
```
aws iam list-policies --query "Policies\[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn" --output text
```

* Create a IAM role and ServiceAccount for the AWS Load Balancer controller, use the ARN from the step above

```
eksctl create iamserviceaccount \
  --cluster=roboshop-dev \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::805778285734:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --region=us-east-1 \
  --approve
```

* Add the EKS chart repo to Helm
```
helm repo add eks https://aws.github.io/eks-charts
```

* Delete the Existing ServiceAccount (Safe if not in Use Yet)

* If the controller isn’t in active use (or you’re setting it up for the first time), delete the ServiceAccount and reinstall:
```
kubectl delete serviceaccount aws-load-balancer-controller -n kube-system
```
* Helm install command for clusters with IRSA:
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=roboshop-dev
```

* check aws-load-balancer-controller is running in kube-system namespace.
```
kubectl get pods -n kube-system
```

```
kubectl get nodes
```

```
kubens roboshop
```

```
kubectl get pods
```

Project components creation on Bastion Server:

# MySQL server created by 30-rds.
# MongoDB

```
aws eks update-kubeconfig --region us-east-1 --name roboshop-dev
```

```
kubectl create namespace roboshop
```

```
git clone https://github.com/rajalingarao/13.8.roboshop-mongodb.git
```

```
cd 13.8.roboshop-mongodb
```
* Login to ECR

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 805778285734.dkr.ecr.us-east-1.amazonaws.com
```

* Build MongoDB image.
```
docker build -t 805778285734.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/mongodb:1.1.1 .
```

* Push image
```
docker push 805778285734.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/mongodb:1.1.1
```

* Now install using Helm. move to helm directory
```
cd helm
```

```
helm upgrade --install mongodb . -n roboshop
```

# Redis
```
aws configure
```
```
aws eks update-kubeconfig --region us-east-1 --name roboshop-dev
```

```
kubectl create namespace roboshop
```

```
git clone https://github.com/rajalingarao/13.9.roboshop-redis.git
```
```
cd 13.9.roboshop-redis/
```

```
helm upgrade --install redis . -n roboshop
```

```
kubectl get pods -n roboshop
```

# RabbitMQ
```
aws eks update-kubeconfig --region us-east-1 --name roboshop-dev
```

```
kubectl create namespace roboshop
```

```
git clone https://github.com/rajalingarao/13.10.roboshop-rabbitmq.git
```

```
cd 13.10.roboshop-rabbitmq
```

* Login to ECR
```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 805778285734.dkr.ecr.us-east-1.amazonaws.com
```

* Build rabbitmq image.
```
docker build -t 805778285734.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/rabbitmq:1.1.2 .
```

* Push image
```
docker push 805778285734.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/rabbitmq:1.1.2
```

* Now install using Helm. move to helm directory
```
cd helm
```

```
helm upgrade --install rabbitmq . -n roboshop
```

# Dispatch
* We use bastion host as Docker server and EKS client.
```
aws configure
```

```
aws eks update-kubeconfig --region us-east-1 --name roboshop-dev
```

```
kubectl create namespace roboshop
```

```
git clone https://github.com/rajalingarao/13.22.roboshop-dispatch.git
```

```
cd 13.22.roboshop-dispatch
```
* Login to ECR

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 805778285734.dkr.ecr.us-east-1.amazonaws.com
```

* Build Dispatch image.
```
docker build -t 805778285734.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/dispatch:1.1.9 .
```

* Push image
```
docker push 805778285734.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/dispatch:1.1.9
```

* Now install using Helm. move to helm directory
```
cd helm
```

```
helm upgrade --install dispatch . -n roboshop
```

# Debug
We use bastion host as Docker server and EKS client.

```
aws configure
```

```
aws eks update-kubeconfig --region us-east-1 --name roboshop-dev
```

```
kubectl create namespace roboshop
```

```
git clone https://github.com/rajalingarao/13.23.roboshop-debug.git
```

```
cd 13.23.roboshop-debug
```

* Login to ECR

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 805778285734.dkr.ecr.us-east-1.amazonaws.com
```

* Build Debug image.
```
docker build -t 805778285734.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/debug:1.1.4 .
```

* Push image
```
docker push 805778285734.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/debug:1.1.4
```

* Now install using Helm. move to helm directory
```
cd helm
```
```
helm upgrade --install debug . -n roboshop
```

All backend CI components created as multi-branch pipeline in jenkins. and all backend CD components created as pipeline in Jenkins and frontend, dispatch, debug.

* Important Point : 

* we have created a branch catalogue-feature-11 for non-prod in backend, There are two branches mainly prod and non-prod. 
* 1. main, 
* 2. catalogue-feature-11,
* 3. catalogue-feature-12 branches.

* we have created a branch cart-feature-21 for non-prod in backend, There are two branches mainly prod and non-prod. 
* 1. main, 
* 2. cart-feature-21,
* 3. cart-feature-22 branches.

* we have created a branch user-feature-31 for non-prod in backend, There are two branches mainly prod and non-prod. 
* 1. main, 
* 2. user-feature-31,
* 3. user-feature-32 branches.

* we have created a branch shipping-feature-11 for non-prod in backend, There are two branches mainly prod and non-prod. 
* 1. main, 
* 2. shipping-feature-41,
* 3. shipping-feature-42 branches.

* we have created a branch payment-feature-51 for non-prod in backend, There are two branches mainly prod and non-prod. 
* 1. main, 
* 2. payment-feature-51,
* 3. payment-feature-52 branches.

* we have created a branch fk-feature-1 for non-prod in frontend, There are two branches mainly prod and non-prod. 
* 1. main, 
* 2. fk-feature-1,
* 3. fk-feature-2 branches.

# Some important points:
* Create a feature branch and switch to it.
* git branch feature-1 -> creating branch and staying in main branch
* git checkout -b feature-1 --> creating branch and switching into feature-1

* Note: In Jenkins CICD, for CI pipeline we will use multibranch pipeline and it has BRANCH_NAME variable exited. Similarly, For CD pipeline, We will use multi-branch pipeline project.  Here running only non-prod branches, called continuous deployment. For prod, need to approvals, called delivery.

* Note: I have faced version 1.8.0. feature-1 already existed in remote repository. You always push changes into main branch, it is the issue. You should push changes into feature-1, feature-2, feature-3.

# Creating Multi branches in catalogue repositories. main points to Prod, we run it non-prod on 'feature branches'

```
git clone https://github.com/rajalingarao/13.11.roboshop-catalogue-CI.git
```

```
cd 13.11.roboshop-catalogue-CI
```
* Create and Switch to the New Branch (recommended):
```
git checkout -b catalogue-feature-11
```
* Push changes into new branch catalogue-feature-11

```
git add .;git commit -m "k8s backend shared library"; git push -u origin catalogue-feature-11;
```
```
git checkout main
```

* Safe delete (recommended)
```
git branch -d catalogue-feature-11
```
* Force delete (if not merged)
```
git branch -D catalogue-feature-11
```

# Creating Multi branches in cart repositories. main points to Prod, we run it non-prod on 'feature branches'
```
git clone https://github.com/rajalingarao/13.15.roboshop-cart-CI.git
```

```
cd 13.15.roboshop-cart-CI
```
* Create and Switch to the New Branch (recommended):

```
git checkout -b cart-feature-21
```

* Push changes into new branch cart-feature-21
```
git add .;git commit -m "k8s backend shared library"; git push -u origin cart-feature-21;
```

```
git checkout main
```
* Safe delete (recommended)
```
git branch -d cart-feature-21;
```
* Force delete (if not merged)
```
git branch -D cart-feature-21;
```
# Creating Multi branches in user repositories. main points to Prod, we run it non-prod on 'feature branches'
```
git clone https://github.com/rajalingarao/13.13.roboshop-user-CI.git
```

```
cd 13.13.roboshop-user-CI
```

* Create and Switch to the New Branch (recommended):
```
git checkout -b user-feature-31
```

* Push changes into new branch user-feature-31
```
git add .;git commit -m "k8s backend shared library"; git push -u origin user-feature-31;
```

```
git checkout main
```
# Creating Multi branches in shipping repositories. main points to Prod, we run it non-prod on 'feature branches'

```
git clone https://github.com/rajalingarao/13.17.roboshop-shipping-CI.git
```

```
cd 13.17.roboshop-shipping-CI
```
* Create and Switch to the New Branch (recommended):
```
git checkout -b shipping-feature-41
```

* Push changes into new branch shipping-feature-41
```
git add .;git commit -m "k8s backend shared library"; git push -u origin shipping-feature-41;
```

```
git checkout main
```

# Creating Multi branches in shipping repositories. main points to Prod, we run it non-prod on 'feature branches'
```
git clone https://github.com/rajalingarao/13.19.roboshop-payment-CI.git
```

```
cd 13.19.roboshop-payment-CI
```
* Create and Switch to the New Branch (recommended):
```
git checkout -b payment-feature-51
```

* Push changes into new branch payment-feature-51
```
git add .;git commit -m "k8s backend shared library"; git push -u origin payment-feature-51;
```

```
git checkout main
```
# Note: Copy the latest target group binding in AWS console and paste into tgb.yaml in frontend.

# Creating pipeline branch in frontend. main points to Prod, we run it non-prod on 'feature branches'.

```
git clone https://github.com/rajalingarao/13.21.roboshop-frontend.git
```

```
cd 13.21.roboshop-frontend
```
* Create and Switch to the New Branch (recommended):
```
git checkout -b feature-121
```

* Push changes into new branch feature-121
```
git add .;git commit -m "k8s backend shared library"; git push -u origin feature-121;
```

```
git checkout main
```

```
kubens roboshop
```

```
kubectl get nodes
```

```
kubectl get pods -n roboshop
```
# After running the entire applications, if running, then trouble shooting the Mysql Database:
* Connect to RDS using bastion host.

```
mysql -h db-dev.lithesh.shop -u root -pRoboShop1
```

```
USE cities;
```

```
select * from cities;
```

* Resource delete steps
* First Delete all applications frontend, backend, db.
* Second Delete all Tools Jenkins, all others
* Third Delete infra and its denpendencies.

* Important Points:

* Note:  Before deploy is the process of calling another pipeline cd-deploy. Now deploy is the creating manifest files.

* Note: We can templatize our application means replacing component values backend, frontend dynamically. For this, We use helm in Kubernetes for templatizing the entire project.

* Note: For EKS Cluster deployment, we use a Pipeline Project, not a multibranch pipeline — so BRANCH_NAME is not available.

For Shared Pipelines, we use Multibranch Pipelines, where BRANCH_NAME is available

* Note: For EKS Cluster deployment, We use Jenkins pipeline project, not the multi branch pipeline. for Shared Pipeline project, we use multi branch pipeline, the default variable available BRANCH_NAME available in multi-branch pipeline, not in pipeline project in Jenkins CICD

