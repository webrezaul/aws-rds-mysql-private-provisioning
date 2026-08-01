#!/bin/bash
set -e

DB_IDENTIFIER="devops-rds"
INSTANCE_CLASS="db.t3.micro"
ENGINE="mysql"
ALLOCATED_STORAGE=20
MAX_ALLOCATED_STORAGE=50
MASTER_USER="admin"
MASTER_PASS="AdminPass123!"

echo "=========================================="
echo " AWS RDS MySQL Private Provisioning Script"
echo "=========================================="

echo "[1/3] Detecting available MySQL 8.4.x engine version..."
MYSQL_VER=$(aws rds describe-db-engine-versions --engine mysql --query "DBEngineVersions[?starts_with(EngineVersion, '8.4')].EngineVersion" --output text | sed 's/[[:space:]].*//')

if [ -z "$MYSQL_VER" ]; then
    echo "Error: Could not find any supported MySQL 8.4.x version in this region."
    exit 1
fi

echo "Found version: $MYSQL_VER"

echo "[2/3] Provisioning RDS instance '$DB_IDENTIFIER'..."
aws rds create-db-instance \
    --db-instance-identifier "$DB_IDENTIFIER" \
    --db-instance-class "$INSTANCE_CLASS" \
    --engine "$ENGINE" \
    --engine-version "$MYSQL_VER" \
    --allocated-storage "$ALLOCATED_STORAGE" \
    --max-allocated-storage "$MAX_ALLOCATED_STORAGE" \
    --master-username "$MASTER_USER" \
    --master-user-password "$MASTER_PASS" \
    --no-publicly-accessible \
    --storage-type gp2

echo "[3/3] Waiting for RDS instance '$DB_IDENTIFIER' to reach 'available' state..."
aws rds wait db-instance-available --db-instance-identifier "$DB_IDENTIFIER"

echo "=========================================="
echo " ✅ RDS Instance '$DB_IDENTIFIER' is AVAILABLE!"
echo "=========================================="
aws rds describe-db-instances \
    --db-instance-identifier "$DB_IDENTIFIER" \
    --query "DBInstances[0].[DBInstanceIdentifier, DBInstanceStatus, EngineVersion, PubliclyAccessible, MaxAllocatedStorage]" \
    --output table
