.PHONY: help bootstrap plan apply destroy destroy-no-confirm validate fmt clean
.DEFAULT_GOAL := help

# Default environment
ENV ?= uat

# =============================================================================
# HELP & INFORMATION
# =============================================================================

help: ## Show this help message
	@echo 'AQUA E-WARRANTY INFRASTRUCTURE MANAGEMENT'
	@echo '========================================='
	@echo 'Usage: make [target] ENV=[uat|staging|prod]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-25s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# BOOTSTRAP & INITIALIZATION
# =============================================================================

bootstrap: ## Initialize Terragrunt backend (S3 + DynamoDB)
	cd terraform/live/$(ENV) && terragrunt init --all --backend-bootstrap

auto-bootstrap: ## Bootstrap without confirmation
	cd terraform/live/$(ENV) && terragrunt init --all --backend-bootstrap --non-interactive

auto-apply: ## Apply all changes without confirmation
	cd terraform/live/$(ENV) && terragrunt apply --all --backend-bootstrap --non-interactive

plan: ## 📋 Plan all changes
	cd terraform/live/$(ENV) && terragrunt plan --all

apply: ## 🔄 Apply with confirmation
	cd terraform/live/$(ENV) && terragrunt apply --all

# =============================================================================
# DESTROY TARGETS
# =============================================================================

destroy: ## Plan destroy then destroy with confirmation
	cd terraform/live/$(ENV) && terragrunt plan --all -destroy && terragrunt destroy --all

auto-destroy: ## 💥 Destroy without confirmation
	cd terraform/live/$(ENV) && terragrunt destroy --all --non-interactive

plan-destroy: ## Plan destroy only
	cd terraform/live/$(ENV) && terragrunt plan --all -destroy

# =============================================================================
# INDIVIDUAL COMPONENTS
# =============================================================================

# Core Infrastructure
vpc-apply: ## Deploy VPC and networking
	cd terraform/live/$(ENV)/vpc && terragrunt apply

s3-apply: ## Deploy S3 buckets
	cd terraform/live/$(ENV)/s3 && terragrunt apply --all

vpc-endpoints-apply: ## Deploy VPC endpoints
	cd terraform/live/$(ENV)/vpc_endpoints && terragrunt apply --all

# Security Layer
kms-apply: ## Deploy KMS keys
	cd terraform/live/$(ENV)/kms && terragrunt apply --all

sg-apply: ## Deploy security groups
	cd terraform/live/$(ENV)/sg && terragrunt apply --all

# Load Balancing Layer
elb-apply: ## Deploy Application Load Balancer
	cd terraform/live/$(ENV)/elb && terragrunt apply

# Database Layer
rds-apply: ## Deploy RDS databases
	cd terraform/live/$(ENV)/rds && terragrunt apply --all

# Container Platform
ecr-apply: ## Deploy ECR repositories
	cd terraform/live/$(ENV)/ecr && terragrunt apply --all

ecs-cluster-apply: ## Deploy ECS infrastructure
	cd terraform/live/$(ENV)/ecs_cluster && terragrunt apply --all

ecs-services-apply: ## Deploy ECS services
	cd terraform/live/$(ENV)/ecs_services && terragrunt apply --all

# CI/CD Platform
codedeploy-apply: ## Deploy CodeDeploy
	cd terraform/live/$(ENV)/codedeploy && terragrunt apply

codebuild-apply: ## Deploy CodeBuild projects
	cd terraform/live/$(ENV)/codebuild && terragrunt apply --all	

codepipeline-apply: ## Deploy CodePipeline
	cd terraform/live/$(ENV)/codepipeline/app && terragrunt apply

# Individual service deployment
ecr-individual-apply: ## Deploy individual ECR repositories
	cd terraform/live/$(ENV)/ecr && terragrunt apply --all

# =============================================================================
# UTILITIES
# =============================================================================

validate: ## ✅ Validate all configurations
	cd terraform/live/$(ENV) && terragrunt validate --all

fmt: ## 🎨 Format all Terraform files
	terragrunt hclfmt
	terraform fmt -recursive terraform/

clean-cache: ## 🧹 Clean Terragrunt cache only
	find . -name ".terragrunt-cache" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
