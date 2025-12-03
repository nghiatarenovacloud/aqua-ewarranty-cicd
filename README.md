# AQUA E-WARRANTY CI/CD Infrastructure

AWS Infrastructure as Code (IaC) with Terraform and Terragrunt for AQUA E-WARRANTY application deployment using ECS Fargate, CodePipeline, and CodeDeploy.

## 🏗️ Architecture Overview

This repository contains a complete CI/CD infrastructure for a .NET 8 application with:

- **Container Platform**: ECS Fargate with blue/green deployments
- **Database Layer**: RDS PostgreSQL and SQL Server with Secrets Manager
- **Storage**: S3 buckets for static files and ALB access logs
- **Load Balancing**: Application Load Balancer with target groups
- **CI/CD Pipeline**: CodePipeline → CodeBuild → CodeDeploy
- **Networking**: VPC with public/private subnets and security groups

## 📋 Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= v1.12.2
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= v0.83.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- [Docker](https://docs.docker.com/get-docker/) for local testing
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) for application development

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Clone the repository
git clone <repository-url>
cd aqua-ewarranty-cicd

# Set environment variables
export ENV="uat"  # or "staging", "prod"
export AWS_PROFILE="your-aws-profile"  # optional
```

### 2. Initial Deployment

```bash
# Initialize Terragrunt backend
make bootstrap ENV=uat

# Deploy complete infrastructure (RECOMMENDED)
make full-deploy ENV=uat
```

### 3. Access Application

After deployment, access your application:
- **Health Dashboard**: `http://<alb-dns>/api/health`
- **Connectivity Tests**: `http://<alb-dns>/api/connectivity`

## 📁 Project Structure

```
aqua-ewarranty-cicd/
├── terraform/
│   ├── modules/                    # Reusable Terraform modules
│   │   ├── vpc/                    # VPC with subnets, NAT, IGW
│   │   ├── ecs/                    # ECS cluster, service, task definitions
│   │   ├── rds/                    # RDS databases with monitoring
│   │   ├── alb/                    # Application Load Balancer
│   │   ├── codepipeline/           # CI/CD pipeline
│   │   ├── codedeploy/             # Blue/green deployment
│   │   └── s3/                     # S3 buckets with policies
│   └── live/                       # Environment configurations
│       └── uat/                    # UAT environment
│           ├── root.hcl            # Root configuration
│           ├── terraform.auto.tfvars.yaml  # Environment variables
│           ├── vpc/                # VPC configuration
│           ├── ecs/                # ECS configuration
│           ├── rds/                # Database configuration
│           ├── alb/                # Load balancer configuration
│           ├── codepipeline/       # CI/CD pipeline
│           └── s3/                 # Storage configuration
├── src/                            # .NET 8 Application
│   └── SampleApp/                  # ASP.NET Core Web API
│       ├── Controllers/            # API controllers
│       ├── Program.cs              # Application entry point
│       └── SampleApp.csproj        # Project file
├── scripts/                        # Deployment scripts
│   ├── validate-dependencies.sh    # Pre-deployment validation
│   └── health-check.sh            # Post-deployment health check
├── buildspec.yml                   # CodeBuild specification
├── appspec.yml                     # CodeDeploy specification
├── taskdef-template.json          # ECS task definition template
├── Dockerfile                      # Container image definition
└── Makefile                        # Infrastructure management commands
```

## 🎯 Available Commands

### Deployment Commands
| Command | Description |
|---------|-------------|
| `make full-deploy ENV=uat` | 🚀 Complete deployment in dependency order (RECOMMENDED) |
| `make quick-deploy ENV=uat` | ⚡ Deploy all resources simultaneously |
| `make plan ENV=uat` | 📋 Plan all changes |
| `make apply ENV=uat` | 🔄 Apply with confirmation |

### Cleanup Commands
| Command | Description |
|---------|-------------|
| `make full-cleanup ENV=uat` | 🧹 Complete cleanup of all resources (RECOMMENDED) |
| `make destroy ENV=uat` | 💥 Destroy Terraform resources only |
| `make force-cleanup ENV=uat` | ⚠️ Force cleanup when normal destroy fails |

### Individual Components
| Command | Description |
|---------|-------------|
| `make vpc-apply ENV=uat` | Deploy VPC and networking |
| `make rds-apply ENV=uat` | Deploy RDS databases |
| `make ecs-apply ENV=uat` | Deploy ECS infrastructure |
| `make codepipeline-apply ENV=uat` | Deploy CI/CD pipeline |

### Utilities
| Command | Description |
|---------|-------------|
| `make status ENV=uat` | 📈 Show infrastructure status |
| `make logs ENV=uat` | 📊 Show recent deployment logs |
| `make validate ENV=uat` | ✅ Validate configurations |
| `make fmt` | 🎨 Format Terraform files |

## 🏛️ Infrastructure Components

### Core Infrastructure
- **VPC**: Multi-AZ setup with public/private subnets
- **Security Groups**: Layered security for ALB, ECS, and RDS
- **S3 Buckets**: Static files and ALB access logs
- **ECR**: Container image registry

### Database Layer
- **RDS PostgreSQL**: Primary application database
- **RDS SQL Server**: Secondary database for legacy systems
- **Secrets Manager**: Secure credential storage
- **Parameter Groups**: Optimized database configurations

### Container Platform
- **ECS Fargate**: Serverless container platform
- **Task Definitions**: Container specifications with secrets
- **Services**: Auto-scaling and load balancing
- **CloudWatch Logs**: Centralized logging

### CI/CD Pipeline
- **CodePipeline**: Orchestrates the deployment workflow
- **CodeBuild**: Builds and tests the application
- **CodeDeploy**: Blue/green deployments with rollback
- **GitHub Integration**: Source code management

### Load Balancing
- **Application Load Balancer**: Layer 7 load balancing
- **Target Groups**: Blue/green deployment targets
- **Health Checks**: Application health monitoring

## 🔧 Configuration Management

### Environment Configuration
Each environment has separate configurations in `terraform.auto.tfvars.yaml`:

```yaml
# UAT Environment Example
aws_region: "ap-southeast-1"
prefix: "aqua"
project: "cicd"
workload: "app"
env: "uat"

vpc_configs:
  vpc_cidr_block: "10.200.16.0/20"
  availability_zones: ["apse1-az1", "apse1-az2"]

ecs_configs:
  cluster:
    name: "cluster"
  task_definition:
    family: "task-v3"
    cpu: "256"
    memory: "512"

rds_configs:
  postgresql:
    engine: "postgres"
    engine_version: "15.7"
    instance_class: "db.t3.micro"
```

### Resource Naming Convention
- Pattern: `{prefix}-{project}-{workload}-{env}-{resource_name}`
- Example: `aqua-cicd-app-uat-cluster`

## 🚢 Deployment Process

### 1. Infrastructure Deployment Order
```
Core Infrastructure → Database Layer → Container Platform → CI/CD Pipeline
```

### 2. Application Deployment Flow
```
Git Push → CodePipeline → CodeBuild → Docker Build → CodeDeploy → ECS Update
```

### 3. Blue/Green Deployment
- **Blue Environment**: Current production traffic
- **Green Environment**: New deployment for testing
- **Traffic Shift**: Gradual migration with rollback capability

## 🔍 Monitoring & Troubleshooting

### Health Endpoints
- **System Health**: `/api/health` - Server metrics and status
- **Connectivity Tests**: `/api/connectivity` - Database and S3 connectivity

### Logging
- **Application Logs**: CloudWatch Logs `/ecs/aqua-cicd-app-uat-task-v3`
- **ALB Access Logs**: S3 bucket `aqua-cicd-app-uat-elb`
- **CodeBuild Logs**: CloudWatch Logs `/aws/codebuild/`

### Common Issues

#### CodeDeploy Blue/Green Deployment Errors

**Error**: `Green taskset target group cannot have non-zero weight prior to traffic shifting`

**Cause**: ALB target group weights are not set correctly for CodeDeploy (requires Blue=100%, Green=0%)

**Solution**: Fix target group weights manually using AWS CLI:

```bash
# Get your ALB listener and target group ARNs
aws elbv2 describe-listeners --load-balancer-arn <your-alb-arn> --region ap-southeast-1
aws elbv2 describe-target-groups --names <blue-tg-name> <green-tg-name> --region ap-southeast-1

# Fix weights (replace ARNs with your actual values)
aws elbv2 modify-listener \
  --listener-arn <your-listener-arn> \
  --default-actions Type=forward,ForwardConfig='{TargetGroups=[{TargetGroupArn=<blue-tg-arn>,Weight=100},{TargetGroupArn=<green-tg-arn>,Weight=0}]}' \
  --region ap-southeast-1

# Verify weights are correct
aws elbv2 describe-listeners --listener-arns <your-listener-arn> --region ap-southeast-1
```

**For UAT Environment Example**:
```bash
aws elbv2 modify-listener \
  --listener-arn arn:aws:elasticloadbalancing:ap-southeast-1:879654127886:listener/app/aqua-cicd-app-uat-alb/78cb613bd57ed8c2/72c485e2c7962b1c \
  --default-actions Type=forward,ForwardConfig='{TargetGroups=[{TargetGroupArn=arn:aws:elasticloadbalancing:ap-southeast-1:879654127886:targetgroup/aqua-cicd-app-uat-alb-blue-tg/b273c1f56bedd5a6,Weight=100},{TargetGroupArn=arn:aws:elasticloadbalancing:ap-southeast-1:879654127886:targetgroup/aqua-cicd-app-uat-alb-green-tg/3e8103aeb01d8a0b,Weight=0}]}' \
  --region ap-southeast-1
```

#### General Troubleshooting
```bash
# Check infrastructure status
make status ENV=uat

# View recent logs
make logs ENV=uat

# Validate configurations
make validate ENV=uat

# Clean up failed deployments
make force-cleanup ENV=uat
```

## 🔒 Security Features

- **VPC Isolation**: Private subnets for databases and applications
- **Security Groups**: Least privilege access rules
- **Secrets Manager**: Encrypted credential storage
- **IAM Roles**: Fine-grained permissions for services
- **ALB SSL**: HTTPS termination (certificate required)

## 🌍 Multi-Environment Support

The infrastructure supports multiple environments:
- **UAT**: `make full-deploy ENV=uat`
- **Staging**: `make full-deploy ENV=staging`
- **Production**: `make full-deploy ENV=prod`

Each environment has isolated:
- AWS resources and state
- Database instances
- Container clusters
- CI/CD pipelines

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `make validate ENV=uat`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.