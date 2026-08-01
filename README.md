# AWS RDS MySQL Private Instance Provisioning using AWS CLI

This repository documents the end-to-end process of provisioning a private MySQL Amazon RDS instance (`devops-rds`) using the AWS CLI, adhering to Free Tier limits and configuring Storage Autoscaling.

---

## 📋 Scenario & Overview

The Nautilus Development Team required a dedicated, secure, and scalable database instance to support a new application feature. The DevOps team was tasked with automating the deployment of a private MySQL RDS instance while maintaining cost optimization via the AWS Free Tier.

### Key Technical Specifications
| Parameter | Configuration |
| :--- | :--- |
| **DB Instance Identifier** | `devops-rds` |
| **Database Engine** | MySQL (Version `8.4.x`) |
| **Instance Class** | `db.t3.micro` (Free Tier Template) |
| **Public Accessibility** | **No** (Private RDS Instance) |
| **Initial Storage** | 20 GB (`gp2` / `gp3`) |
| **Storage Autoscaling Threshold** | 50 GB (`--max-allocated-storage 50`) |
| **Master Username** | `admin` |

---

## 🚀 Quick Start / Automation Script

You can execute the automated deployment script [`deploy.sh`](./deploy.sh):

```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 🛠 Step-by-Step AWS CLI Commands

### 1. Check Available Engine Version
Detect the latest available MySQL `8.4.x` engine version in your AWS region:

```bash
aws rds describe-db-engine-versions \
    --engine mysql \
    --query "DBEngineVersions[?starts_with(EngineVersion, '8.4')].EngineVersion" \
    --output text
```

### 2. Provision Private RDS Instance
Create the `devops-rds` instance with private networking and storage autoscaling up to 50 GB:

```bash
# Fetch available MySQL 8.4 version
MYSQL_VER=$(aws rds describe-db-engine-versions --engine mysql --query "DBEngineVersions[?starts_with(EngineVersion, '8.4')].EngineVersion" --output text | sed 's/[[:space:]].*//')

# Create DB instance
aws rds create-db-instance \
    --db-instance-identifier devops-rds \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --engine-version "$MYSQL_VER" \
    --allocated-storage 20 \
    --max-allocated-storage 50 \
    --master-username admin \
    --master-user-password "AdminPass123!" \
    --no-publicly-accessible \
    --storage-type gp2
```

### 3. Verify & Wait for Instance Readiness
Wait until the RDS instance reaches the `available` state before proceeding:

```bash
# Wait until available
aws rds wait db-instance-available --db-instance-identifier devops-rds

# Query status
aws rds describe-db-instances \
    --db-instance-identifier devops-rds \
    --query "DBInstances[0].[DBInstanceIdentifier, DBInstanceStatus, EngineVersion, PubliclyAccessible, MaxAllocatedStorage]" \
    --output table
```

---

## 🔍 Verification

Upon completion, `describe-db-instances` will confirm:
- `DBInstanceStatus`: `available`
- `PubliclyAccessible`: `False`
- `MaxAllocatedStorage`: `50`

---

## 🧹 Cleanup (Optional)

To delete the RDS instance and prevent incurring costs after testing:

```bash
aws rds delete-db-instance \
    --db-instance-identifier devops-rds \
    --skip-final-snapshot \
    --delete-automated-backups
```
