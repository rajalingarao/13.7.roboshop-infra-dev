# Roboshop infra dev creation and deletion 

```
for i in 00-vpc/ 10-sg/ 20-bastion/ 30-rds/ 40-eks/ 50-acm/ 60-alb/ 70-ecr/ 80-cdn/ ; do cd $i; terraform init -reconfigure; cd .. ; done 
```
```
for i in  00-vpc/ 10-sg/ 20-bastion/ 30-rds/ 40-eks/ 50-acm/ 60-alb/ 70-ecr/ 80-cdn/  ; do cd $i; terraform plan; cd .. ; done 
```
```
for i in  00-vpc/ 10-sg/ 20-bastion/ 30-rds/ 40-eks/ 50-acm/ 60-alb/ 70-ecr/ 80-cdn/ ; do cd $i; terraform apply -auto-approve; cd .. ; done 
```
```
for i in  80-cdn/ 70-ecr/ 60-alb/ 50-acm/ 40-eks/ 30-rds/ 20-bastion/ 10-sg/ 00-vpc/  ; do cd $i; terraform destroy -auto-approve; cd .. ; done 
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

## RDS Configuration
* Since we are using RDS instead of MySQL image, we need to configure RDS manually, we are creating schema as part of RDS but table and user should be created.
* Make sure MySQL instance allows port no 3306 from bastion

```
mysql -h roboshop-dev.cm9mcies2otg.us-east-1.rds.amazonaws.com -u root -pRoboShop1
```
* Clone shipping component into bastion
```
git clone https://github.com/Lingaiahthammisetti/13.17.roboshop-shipping-CI.git
```
* logout from mysql and Load the data into mysql on ec2-user.
```
mysql -h roboshop-dev.cm9mcies2otg.us-east-1.rds.amazonaws.com -u root -pRoboShop1 < 13.17.roboshop-shipping-CI/db/schema.sql
```
```
mysql -h roboshop-dev.cm9mcies2otg.us-east-1.rds.amazonaws.com -u root -pRoboShop1 < 13.17.roboshop-shipping-CI/db/app-user.sql
```
```
mysql -h roboshop-dev.cm9mcies2otg.us-east-1.rds.amazonaws.com -u root -pRoboShop1 < 13.17.roboshop-shipping-CI/db/master-data.sql
```

## Target group binding
* If we are running frontend using normal user it can't bind the port 80. non root privelege user running container are not able to open system ports which are under 1024.
* So we have to use port no 8080 for frontend. Make sure
    * nginx.conf opens port no 8080 instead of 80.
    * ALB target group health check port should be 8080.
    * frontend service target port should be 8080 instead of 80.

## Ingress Controller

* Login to bastion host and get the kubeconfig of EKS cluster
```
aws configure
```

```
aws eks update-kubeconfig --region us-east-1 --name roboshop-dev
```

```
kubectl get nodes
```

* Create namespace roboshop
```
kubectl create namespace roboshop
```

* IAM policy

```
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.10.0/docs/install/iam_policy.json
```

* IAM Role created
```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json
```

* (Optional) Use Existing Policy:
```
aws iam list-policies --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn" --output text

```

* Create Service account. Replace your account ID.
```
eksctl create iamserviceaccount \
--cluster=roboshop-dev \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::484907532817:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--region us-east-1 \
--approve
```



* Install aws load balancer controller drivers through helm.

```
helm repo add eks https://aws.github.io/eks-charts
```

* Reuse the existing ServiceAccount (recommended if it was created correctly by eksctl)
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=roboshop-dev \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

```




* Delete the Existing ServiceAccount (Safe if not in Use Yet)
* If the controller isn’t in active use (or you’re setting it up for the first time), delete the ServiceAccount and reinstall:
```
kubectl delete serviceaccount aws-load-balancer-controller -n kube-system
```
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=roboshop-dev --set serviceAccount.create=true --set serviceAccount.name=aws-load-balancer-controller
```
* Make sure load balancer pods are running
```
kubectl get pods -n kube-system
```

# Jenkkns CICD Master and Agent creation and deletion 
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
* Setup Agent-1 and create credentials ssh-auth, aws-creds-dev.

Login into Bastion server:
```
aws configure
```
* aws s3 ls  (or) aws sts get-caller-identity

# Jenkins

Install below plugins when you started Jenkins.

Plugins:
* Pipeline stage view
* Pipeline Utility Steps
* AWS Credentials
* AWS Steps
* Rebuild
* Ansi Color
* Sonarqube Scanner

Restart Jenkins once plugins are installed

### Manage Credentials:
* We need to add ssh credentials for Jenkins to connect to agent. I am using ID as ssh-auth
* We need to add aws credentials for Jenkins to connect with AWS for deployments. I am using
    * aws-creds-dev
    * aws-creds-prod
    * aws-creds

### Configure Agent

### Configure Jenkins Shared Libraries
* Go to Manage Jenkins -> System
* Find Global Trusted Pipeline Libraries section
* Name as jenkins-shared-library, default version main and load implicitly
* Location is https://github.com/Lingaiahthammisetti/13.5.jenkins-shared-library-roboshop.git

Now Jenkins is ready to use.


# Mysql:  Please load mysql data using shipping-ci.


# MongoDB

We use bastion host as Docker server and EKS client.
Make sure `aws configure` is done in bastion and connected to EKS cluster.
```
aws eks update-kubeconfig --region us-east-1 --name roboshop-dev
```
```
kubectl get nodes
```
```
kubectl create namespace roboshop
```
```
kubens roboshop
```

```
git clone https://github.com/Lingaiahthammisetti/13.8.roboshop-mongodb.git
```
```
cd 13.8.roboshop-mongodb
```

* Login to ECR
```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 484907532817.dkr.ecr.us-east-1.amazonaws.com
```
* Build MongoDB image.
```
docker build -t 484907532817.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/mongodb:v1.1.1 .
```
* Push image
```
docker push 484907532817.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/mongodb:v1.1.1
```
* Now install using Helm. move to helm directory
```
cd helm
```

```
helm upgrade --install mongodb . -n roboshop
```
# Redis
Note:  image: redis  # this is image pulled from internet, not customized.

```
git clone https://github.com/Lingaiahthammisetti/13.9.roboshop-redis.git
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
# Rabbitmq
```
git clone https://github.com/Lingaiahthammisetti/13.10.roboshop-rabbitmq.git
```
```
cd 13.10.roboshop-rabbitmq
```

* Login to ECR
```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 484907532817.dkr.ecr.us-east-1.amazonaws.com
```
* Build rabbitmq image.
```
docker build -t 484907532817.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/rabbitmq:v1.1.2 .
```
* Push image
```
docker push 484907532817.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/rabbitmq:v1.1.2
```
* Now install using Helm. move to helm directory
```
cd helm
```

```
helm upgrade --install rabbitmq . -n roboshop
```

Next Create CI and CD for backend services catalogue, cart, user, shipping, payment.

We use multi-branch pipeline for all CI job like catalogue-ci, cart-ci, user-ci, shipping-ci, payment-ci.
We use pipeline project for all CD job like catalogue-cd, cart-cd, user-cd, shipping-cd, payment-cd.
We use pipeline project for remaining projects frontend, dispatch, debug.

* Catalogue CI is multi-branch pipeline and there are two branch one is main branch pointing to production. Second is feature branch for frequently doing changes like dev code.
similarly will do other services also.
raoli@LAPTOP-VCM4BOUV MINGW64 /c/devops/daws-78s/repos/13.11.roboshop-catalogue-CI (main)
$ git checkout feature

raoli@LAPTOP-VCM4BOUV MINGW64 /c/devops/daws-78s/repos/13.11.roboshop-catalogue-CI (feature)
Please update the application code and push into feature branch.

raoli@LAPTOP-VCM4BOUV MINGW64 /c/devops/daws-78s/repos/13.11.roboshop-catalogue-CI (feature)
$ git add .;git commit -m "roboshop infra dev";git push -u origin feature;

$git checkout main



First Create aws-creds-dev credentials using AWS Credentials plugin.


# Dispatch

```
git clone https://github.com/Lingaiahthammisetti/13.22.roboshop-dispatch.git
```
```
cd 13.22.roboshop-dispatch
```

* Login to ECR
```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 484907532817.dkr.ecr.us-east-1.amazonaws.com
```
* Build Dispatch image.
```
docker build -t 484907532817.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/dispatch:v1.1.8 .
```
* Push image
```
docker push 484907532817.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/dispatch:v1.1.8
```
* Now install using Helm. move to helm directory
```
cd helm
```

```
helm upgrade --install dispatch . -n roboshop
```

# Debug

```
git clone https://github.com/Lingaiahthammisetti/13.23.roboshop-debug.git
```
```
cd 13.23.roboshop-debug
```

* Login to ECR
```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 484907532817.dkr.ecr.us-east-1.amazonaws.com
```
* Build Debug image.
```
docker build -t 484907532817.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/debug:v1.1.9 .
```
* Push image
```
docker push 484907532817.dkr.ecr.us-east-1.amazonaws.com/roboshop/dev/debug:v1.1.9
```
* Now install using Helm. move to helm directory
```
cd helm
```

```
helm upgrade --install debug . -n roboshop
```

