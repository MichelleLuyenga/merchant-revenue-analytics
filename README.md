# Merchant Performance & Revenue Analytics Dashboard

> **End-to-end data pipeline and BI dashboard for tracking merchant acquisition, revenue performance, and churn analytics.**

## 📊 Project Overview

Built a complete analytics pipeline that transforms raw transactional data into actionable business intelligence for merchant acquisition and revenue optimization. This project demonstrates the full data analytics workflow: database design → ETL → advanced SQL analytics → BI visualization.

## 🏗️ Architecture

```
Supabase (PostgreSQL) → Advanced SQL Queries → Looker Studio Dashboard
↓ ↓ ↓
[Data Storage] [Analytics Engine] [Visualization]
```

## 🔧 Tech Stack

- **Database:** PostgreSQL (Supabase)
- **Analytics:** Advanced SQL (CTEs, Window Functions, Aggregations)
- **Visualization:** Google Looker Studio (connected via PostgreSQL connector)
- **Version Control:** Git/GitHub

## 📈 Key Metrics Tracked

- **Monthly Recurring Revenue (MRR)** & Commission Payouts
- **Channel Performance** (Direct Sales vs Digital vs Agency vs Partner)
- **Customer Churn Rate** (monthly cumulative analysis)
- **Revenue Leakage Detection** (refund rates, chargebacks, inactive merchants)
- **Merchant Concentration Risk** (top merchant revenue share)

## 🗄️ Database Schema

### Tables
- **merchants** - Merchant profiles with acquisition channel and status
- **transactions** - Payment transactions with commission tracking

### Key Relationships
- One-to-Many: merchants → transactions
- Referential integrity enforced with foreign keys
- Indexed on critical query columns (channel, status, dates)

## 📊 Sample Analytical Queries

### 1. Monthly Revenue & Commission Analysis
Uses CTEs and conditional aggregation to calculate:
- Gross vs Net Revenue (accounting for refunds/chargebacks)
- Effective commission rates
- Month-over-month growth trends

### 2. Channel Performance Ranking
Leverages window functions (`RANK()`, `SUM() OVER()`) to:
- Rank acquisition channels by revenue contribution
- Calculate revenue per active merchant by channel
- Analyze channel market share percentages

### 3. Churn Rate Analysis
- Tracks cumulative churn over time
- Calculates net merchant growth/loss per month
- Identifies churn patterns by acquisition cohort

### 4. Revenue Leakage Detection
- Flags merchants with >15% refund rates
- Identifies inactive but "Active" status merchants
- Tracks chargeback incidents

## 📸 Dashboard Screenshots

![Dashboard Overview](screenshots/dashboard_overview.png)
![Channel Performance](screenshots/channel_performance.png)
![Revenue Trends](screenshots/revenue_trends.png)

## 🚀 How to Reproduce

1. **Set up Supabase Project**
   - Create a new project at [supabase.com](https://supabase.com)
   - Open SQL Editor

2. **Run Schema & Seed Script**
   - Execute `schema_and_seed.sql` in the SQL Editor
   - This creates tables and populates 50 merchants + 500+ transactions

3. **Connect Looker Studio**
   - Go to [Looker Studio](https://lookerstudio.google.com)
   - Add PostgreSQL data source
   - Use your Supabase connection string (Settings → Database → Connection string)
   - Enable SSL

4. **Explore Analytics**
   - Run queries from `analytical_queries.sql`
   - Create visualizations based on the data

## 📝 Skills Demonstrated

- **SQL Proficiency:** CTEs, Window Functions, Complex JOINs, Aggregations
- **Data Modeling:** Relational schema design with proper indexing
- **Business Intelligence:** KPI definition, dashboard design, data storytelling
- **Data Quality:** Revenue leakage detection, anomaly identification
- **Tool Integration:** Database-to-BI pipeline setup

## 🔜 Future Enhancements

- [ ] Add dbt for data transformation layer
- [ ] Implement incremental data refresh
- [ ] Add predictive churn model using merchant activity patterns
- [ ] Create automated email reports from dashboard data

---

*Built as part of a data analytics portfolio project.*