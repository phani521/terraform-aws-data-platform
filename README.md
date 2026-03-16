# terraform-aws-data-platform
# Terraform AWS Data Platform (EMR & EKS)

This repository provisions a shared VPC plus separate **EMR** and **EKS** clusters in `us-east-1` using Terraform, with GitHub Actions CI/CD and Terraform workspaces for `dev` and `prod`.

---

## 1. Architecture Overview

- **Region**: `us-east-1`
- **State backend**: S3 (+ DynamoDB lock)
- **Shared VPC**: `modules/network`
- **EMR cluster**: `modules/emr` (Spark, autoscaling, default EMR security configuration)
- **EKS cluster**: `modules/eks` (managed node group with autoscaling)
- **Environments**: `dev` and `prod` via Terraform workspaces
- **CI/CD**:
  - `emr-ci-cd.yml`: Plans/applies EMR stack
  - `eks-ci-cd.yml`: Plans/applies EKS stack
  - Plan on PR, apply to `prod` only after manual approval on `main`

---

## 2. Prerequisites

1. **Tools on your machine**
   - Terraform `>= 1.6.0`
   - AWS CLI configured
   - Git and a GitHub account

2. **AWS resources**
   - S3 bucket for Terraform state:
     - Name in code: `ppd-terraform-state`
   - DynamoDB table for state locking:
     - Name in code: `ppd-terraform-locks`
     - Primary key: `LockID` (string)

3. **AWS credentials**
   - IAM user or role with permissions for:
     - VPC, Subnets, Security Groups
     - EC2, EMR, EKS, IAM
     - S3, DynamoDB, CloudWatch
   - Locally, export:
     ```bash
     export AWS_ACCESS_KEY_ID=YOUR_KEY
     export AWS_SECRET_ACCESS_KEY=YOUR_SECRET
     export AWS_DEFAULT_REGION=us-east-1
     ```

4. **GitHub repository**
   - Create a repo (e.g. `terraform-aws-data-platform`)
   - Push this code into the repo

5. **GitHub Secrets**
   - In **Settings → Secrets and variables → Actions → New repository secret**:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`

6. **GitHub environment for manual approval**
   - In **Settings → Environments**:
     - Create environment `production`
     - Add required reviewers (optional but recommended)

---

## 3. Project Structure

```text
.
├─ providers.tf          # AWS provider, S3 backend (us-east-1)
├─ versions.tf           # Global variables (region)
├─ modules/
│  ├─ network/           # Shared VPC + private subnets
│  ├─ emr/               # EMR cluster + IAM + autoscaling
│  └─ eks/               # EKS cluster using terraform-aws-eks module
├─ emr/                  # EMR root (wire modules + workspaces)
│  ├─ main.tf
│  ├─ variables.tf
│  └─ outputs.tf
├─ eks/                  # EKS root (wire modules + workspaces)
│  ├─ main.tf
│  ├─ variables.tf
│  └─ outputs.tf
└─ .github/workflows/
   ├─ emr-ci-cd.yml      # EMR pipeline
   └─ eks-ci-cd.yml      # EKS pipeline
