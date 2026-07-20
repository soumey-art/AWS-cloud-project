# AWS Cloud Project — Company Inventory Control System

A scalable, secure, highly available web application deployed on AWS using Terraform. Users can add products (name, description, price, image) stored in RDS (PostgreSQL) and S3 (images), served behind an Application Load Balancer across 2 AZs.

## Architecture

```
Users → ALB (port 80, HTTP) → 2× EC2 t3.micro (port 3000) → RDS PostgreSQL 16.3
                                  ↕
                     S3 (product images — AES256 encrypted)
                                  ↕
                CloudWatch (logs, dashboard, 3 alarms + SNS)
```

- **VPC**: 10.0.0.0/16 with public subnets (EC2) + private subnets (RDS), IGW for internet access
- **EC2**: Amazon Linux 2023, t3.micro, public IPs, IAM instance profile (S3 + CloudWatch)
- **Auto Scaling**: Min 2, Desired 2, Max 4, CPU target 60%
- **RDS**: PostgreSQL 16.3, db.t3.micro, 20GB, not publicly accessible
- **S3**: AES256 encrypted, Block Public Access enabled
- **Security Groups**: ALB→EC2 (port 3000) → RDS (port 5432), least-privilege chain
- **Monitoring**: CloudWatch Dashboard (6 widgets), 3 alarms (cpu-high, unhealthy-hosts, target-5xx), SNS topic

## URLs

| Resource | URL |
|----------|-----|
| Website | http://rith-project-alb-12515995.us-east-1.elb.amazonaws.com/ |
| Health Check | http://rith-project-alb-12515995.us-east-1.elb.amazonaws.com/health |
| API (JSON) | http://rith-project-alb-12515995.us-east-1.elb.amazonaws.com/api/products |
| CloudWatch Dashboard | https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=Rith-Cloud-Project-Dashboard |
| GitHub | https://github.com/soumey-art/AWS-cloud-project |

## Credentials (Keep Secret — Do Not Commit)

| Variable | Value |
|----------|-------|
| DB Host | `rith-cloud-db.cunuksekskkl.us-east-1.rds.amazonaws.com` |
| DB Port | 5432 |
| DB Name | `inventorydb` |
| DB User | `dbadmin` |
| DB Password | `Qs-B3WLwxw1jJbeb4CegeFJXPgNua_TV` |
| S3 Bucket | `rith-cloud-project-storage20260720051220960100000001` |
| AWS Region | `us-east-1` |
| AWS Account | `574548986883` |

## Project Structure

```
rith-cloud-project/
├── app/                        # Node.js/Express application code (Donal)
│   ├── server.js               # Express server, port 3000
│   ├── db/pool.js              # pg Pool with SSL config
│   ├── db/init.js              # Creates products table
│   ├── s3.js                   # S3 image upload (multer memory → S3)
│   ├── views/index.ejs         # Homepage template
│   └── package.json
├── terraform/                  # Infrastructure as Code (Vanrith)
│   ├── provider.tf             # AWS provider ~> 5.0
│   ├── variables.tf            # Shared variables
│   ├── outputs.tf              # ALB DNS, RDS endpoint, etc.
│   ├── vpc.tf                  # VPC, subnets, IGW, route tables
│   ├── security.tf             # 3 SGs (alb-sg, ec2-sg, rds-sg) — Soumey
│   ├── iam.tf                  # IAM role, S3 policy, CW attachment — Soumey
│   ├── compute.tf              # ALB, target group, listener, ASG — Dara
│   ├── storage.tf              # RDS PostgreSQL + S3 — Vanrith
│   ├── monitoring.tf           # CW dashboard, alarms, SNS — Omrin
│   ├── user_data.tftpl         # Bootstrap script (Node.js, pm2, CW agent)
│   └── terraform.tfvars.example
├── README.md
└── .gitignore
```

## Deployment

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # fill in db_password
terraform init
terraform validate
terraform plan
terraform apply
```

## Testing Summary

| Test | Result |
|------|--------|
| Website loads via ALB DNS | ✅ HTML page renders |
| Health endpoint | ✅ `{"status":"healthy"}` HTTP 200 |
| RDS insert + retrieve | ✅ 4 products stored |
| S3 file upload | ✅ PNG stored in `products/` folder |
| 2 healthy instances in 2 AZs | ✅ us-east-1a + us-east-1b |
| CloudWatch logs collected | ✅ user-data, app-out, app-error streams |
| Alarm ALARM→OK | ✅ `cpu-high` demonstrated |
| Instance termination recovery | ✅ ASG replaces automatically |

## Cost Estimate (Monthly)

| Service | Spec | Cost |
|---------|------|------|
| EC2 (2× t3.micro) | 2 vCPU, 1GB RAM each | ~$30 |
| Application Load Balancer | + data processing | ~$17 |
| RDS (db.t3.micro) | PostgreSQL 16.3, 20GB SSD | ~$27 |
| S3 | Minimal usage | ~$1 |
| **Total** | | **~$75-80/mo** |

## Team

| Person | Role | Responsibilities |
|--------|------|-----------------|
| Vanrith | Infrastructure Lead | VPC, subnets, IGW, RDS, S3, Terraform integration |
| Dara | High Availability & Scaling | ALB, Launch Template, ASG, scaling policy |
| Soumey | Security | SGs, IAM roles, encryption, S3 block public access |
| Omrin | Monitoring & Logging | CW dashboard, log group, 3 alarms, SNS topic |
| Donal | Application Deployment | Node.js app, RDS queries, S3 upload, /health, pm2 |

## Known Issues

- S3 image URLs return 403 in browser (Block Public Access). Fix: use presigned URLs in the app.
- No SNS email subscription confirmed (topic exists, needs email confirmation).
- No formal failure recovery or scaling test documented.
