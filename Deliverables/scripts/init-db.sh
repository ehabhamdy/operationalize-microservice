#!/bin/bash

# Get the PostgreSQL pod name
POD_NAME=$(kubectl get pod -l app=postgresql -o jsonpath='{.items[0].metadata.name}')
echo "PostgreSQL Pod: $POD_NAME"

# Database credentials
DB_USER="myuser"
DB_NAME="mydatabase"

echo ""
echo "Copying SQL files to pod..."
kubectl cp db/1_create_tables.sql $POD_NAME:/tmp/1_create_tables.sql
kubectl cp db/2_seed_users.sql $POD_NAME:/tmp/2_seed_users.sql
kubectl cp db/3_seed_tokens.sql $POD_NAME:/tmp/3_seed_tokens.sql

echo ""
echo "Creating tables..."
kubectl exec $POD_NAME -- psql -U $DB_USER -d $DB_NAME -f /tmp/1_create_tables.sql

echo ""
echo "Seeding tables..."
kubectl exec $POD_NAME -- psql -U $DB_USER -d $DB_NAME -f /tmp/2_seed_users.sql
kubectl exec $POD_NAME -- psql -U $DB_USER -d $DB_NAME -f /tmp/3_seed_tokens.sql
kubectl exec $POD_NAME -- psql -U $DB_USER -d $DB_NAME -c "\dt"

echo ""
echo "Checking record counts..."
kubectl exec $POD_NAME -- psql -U $DB_USER -d $DB_NAME -c "SELECT 'users' as table_name, COUNT(*) as count FROM users UNION ALL SELECT 'tokens', COUNT(*) FROM tokens;"

echo ""
echo "✅ Database Initialization Complete!"

