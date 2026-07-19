# AWS Cloud Project

## AWS Scalable, Secure, and Highly Available Web Application

This repository contains the Infrastructure as Code (IaC) configuration and application source code for a scalable, secure, and highly available web application deployed on Amazon Web Services (AWS) using Terraform.

---

## 🏗️ Architecture Overview

The system is architected across **two Availability Zones (AZs)** to ensure high availability and resilience. The core architecture includes:

- **VPC Configuration:** Isolated network setup featuring public subnets for external routing and private subnets for backend resources.
- **Elastic Load Balancer (ALB):** Distributes incoming public HTTP web traffic across a dynamic fleet of web servers.
- **Auto Scaling Group (ASG):** Automatically provisions, maintains, and recovers EC2 instances dynamically based on traffic parameters (Min: 2, Desired: 2, Max: 4).
- **Data & Storage Layer:** Amazon RDS instance for application data retention and an Amazon S3 bucket for media asset uploads.
- **Security Infrastructure:** Network firewalls via Security Groups and identity lifecycle permissions using IAM Instance Profiles strictly enforcing least-privilege principles.
- **Observability Platform:** Integrated CloudWatch agents monitoring instance system health metrics, centralizing access/error logs, and managing critical thresholds via alarms.

---

## 📂 Project Repository Structure

The workspace is organized into explicit logical directories to facilitate smooth team collaboration across feature branches:

```text
aws-cloud-project/
├── app/                  # Application runtime, dependencies, and stateless logic (Donal)
├── terraform/            # Infrastructure as Code baseline modules (Vanrith)
│   ├── provider.tf       # Cloud provider and version specifications
│   ├── variables.tf      # Global parameters and variable definitions
│   ├── outputs.tf        # Computed infrastructure deployment parameters
│   ├── network.tf        # Baseline VPC and core routing infrastructure
│   ├── security.tf       # Security Groups and firewall ingress/egress rules (Soumey)
│   ├── iam.tf            # Least-privilege roles, policies, and profiles (Soumey)
│   ├── compute.tf        # Launch templates, ALB, target groups, and ASG configurations (Dara)
│   ├── storage.tf        # Isolated RDS databases and encrypted S3 bucket specifications
│   └── monitoring.tf     # CloudWatch metrics, dashboards, and log groups (Omrin)
├── docs/                 # Engineering architecture diagrams and cost summaries
└── README.md             # Integration workflow and deployment guide
```
🔒 Security Best Practices

Our system strictly aligns with AWS security best practices and least-privilege design principles:

1. Network Isolation: Public traffic is terminated strictly at the Application Load Balancer. EC2 instances only process requests coming from the ALB security group, and the Amazon RDS instance only accepts database queries originating from the EC2 web servers.
2. Least-Privilege Profiles: EC2 nodes run on localized IAM Instance Profiles, avoiding embedded security credentials in application configurations.
3. Credential Management: The configuration uses an untracked local terraform.tfvars file to parse sensitive parameters (like database credentials), preventing credential leaks on public/private repositories.

🛠️ Deployment Instructions
Prerequisites
Terraform CLI installed locally.
AWS CLI installed and configured with appropriate project deployment credentials.

Step-by-Step Initialization
1. Clone the repository and navigate to the infrastructure workspace:
```Bash
git clone <your-repository-url>
cd aws-cloud-project/terraform
```

2. Initialize the backend providers and local configurations:
   ```Bash
   terraform init
   ```
3. Validate code syntax and configurations:
   ```Bash
   terraform validate
   ```
4. Perform a dry-run plan execution to preview infrastructural mutations:
   ```Bash
   terraform plan
   ```
5. Apply and build the cloud infrastructure:
   ```Bash
   terraform apply
   ```
👥 Team Work Assignments
- Vanrith (Infrastructure Lead): Core VPC foundation, routing parameters, relational data layers, global variable integrations, and root module composition.
- Dara (High Availability & Scaling): Compute layers, launch configurations, ALB listener routing rules, and auto-scaling scaling matrix validations.
- Soumey (Security Engineer): Identity Access Management architecture, secure ingress/egress security profiles, and resource layer encryption rules.
- Omrin (Monitoring & Logging): CloudWatch agent collection configurations, target error alarms, metric tracking, and operational dashboards.
- Donal and Soumey (Software Deployment Lead): Stateless web application prototyping, API health endpoints, data routing procedures, and shell automation scripts.

📌 Notes

This project demonstrates a production-style AWS architecture focused on scalability, security, high availability, and operational monitoring using Terraform as the Infrastructure as Code framework.
