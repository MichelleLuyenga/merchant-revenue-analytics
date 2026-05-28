# Looker Studio Dashboard Setup Guide

## Connection Configuration

1. **Connector:** PostgreSQL
2. **Host:** `db.[YOUR-PROJECT-REF].supabase.co`
3. **Port:** `5432`
4. **Database:** `postgres`
5. **Username:** `postgres`
6. **Password:** `[YOUR-DATABASE-PASSWORD]`
7. **SSL:** Required

## Custom Queries for Charts

### Total Transaction Volume Scorecard
```sql
SELECT 
  SUM(CASE WHEN transaction_type = 'payment' THEN amount ELSE 0 END) -
  SUM(CASE WHEN transaction_type = 'refund' THEN amount ELSE 0 END) AS net_revenue
FROM transactions;