# Coworking Space Analytics Microservice Deployment

## Prerequisites

### 1. Create ECR Repository
I created the ECR repository directly on the AWS console. To enable EKS to pull the image, you can add a permission with the following policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowEKSNodeRole",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::<account-id>:role/<your-node-role-name>"
        },
        "Action": [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
}
```

### 2. Create CodeBuild Project
I created the CodeBuild project directly on the AWS console. To enable CodeBuild to push the image to ECR, you can add a the AWS Managed Policy: `AmazonEC2ContainerRegistryPowerUser`

### 3. Create EKS Cluster

Spin a simple EKS cluster with the following command:
```bash
eksctl create cluster --name coworking-cluster --region us-east-1 --nodegroup-name coworking-nodes --node-type t3.small --nodes 1 --nodes-min 1 --nodes-max 2
```

Check Kubectl context:
```bash
kubectl config current-context
```

### 4. Enabeling Cloudwatch Logs

Attach the CloudWatchAgentServerPolicy to the EKS cluster nodes role:
```bash
aws iam attach-role-policy \
--role-name <worker-node-role-name> \
--policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy 
```

To get the worker node name, run the following command:
```bash
aws eks describe-nodegroup \                                                                                              <aws:devops>
  --cluster-name <cluster-name> \
  --nodegroup-name <node-group-name> \
  --query 'nodegroup.nodeRole' \
  --output text | awk -F'/' '{print $NF}
```

Install the Amazon CloudWatch Observability EKS add-on:
```bash
aws eks create-addon --addon-name amazon-cloudwatch-observability --cluster-name <cluster-name>
```


## Deployment Steps

### 1. Deploy ConfigMap and Secrets
```bash
kubectl apply -f deployments/configmap.yaml
```

### 2. Deploy PostgreSQL Database
```bash
kubectl apply -f deployments/pv.yaml
kubectl apply -f deployments/pvc.yaml
kubectl apply -f deployments/postgresql-deployment.yaml
kubectl apply -f deployments/postgresql-service.yaml
```

Verify PostgreSQL is running:
```bash
kubectl get pods
kubectl get services
```

### 3. Initialize Database
Run the database initialization script to create tables and seed data:
```bash
cd ..
bash scripts/init-db.sh
```

### 4. Deploy Coworking Application
```bash
kubectl apply -f deployments/coworking.yaml
```

### 5. Verify Deployment
Check if all pods are running:
```bash
kubectl get pods
kubectl get services
```

### 6. Access the Application
Get the LoadBalancer URL:
```bash
kubectl get service coworking
```

Wait for the LoadBalancer IP dns name to be assigned, then access the application at:
```
http://<LOAD-BALANCER-IP-DNS-NAME>/api/health_check
```
## Releasing new version:
1. Developers push the changes to the main branch
2. CodeBuild project pickup the changes and trigger a new build.
3. CodeBuild project builds the Docker image and pushes it to ECR
4. CodeBuild project updates the Kubernetes deployment manifest with the new image (otherwise, the developer can manually update the manifest with the new image tag)
5. Developer apply the new manifest to the EKS cluster (ideally with ArgoCd)
6. New version is deployed and available to the users.

## Test API Endpoints
```bash
# Health check
curl http://<LOAD-BALANCER-IP-DNS-NAME>/api/health_check

# Get daily usage
curl http://<LOAD-BALANCER-IP-DNS-NAME>/api/reports/daily_usage

# Get user visits
curl http://<LOAD-BALANCER-IP-DNS-NAME>/api/reports/user_visits
```

## Troubleshooting
View pod logs:
```bash
kubectl logs -l service=coworking --tail=50
```

Describe pod for more details:
```bash
kubectl describe pod -l service=coworking
```

## Improvements:
- In real world, kubernetes deployments are managed with ArgoCd to automate the deployment process.
- (critical) Secrets are managed with AWS Secrets Manager and External Secrets Operator
- Monitoring and logging are managed with Prometheus and Grafana.
- Use Infrastructure as Code (IaC) with Terraform to manage the infrastructure (creating the EKS cluster, ECR repository, CodeBuild project, etc.)
