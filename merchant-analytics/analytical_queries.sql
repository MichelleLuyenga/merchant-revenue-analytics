-- ============================================
-- ANALYTICAL QUERY SUITE
-- Merchant Performance & Revenue Analytics
-- ============================================

-- QUERY 1: Monthly Recurring Revenue (MRR) & Commission Payouts
-- Calculates gross transaction volume, net revenue (after refunds), and company commission
-- ============================================
WITH monthly_financials AS (
    SELECT 
        DATE_TRUNC('month', t.transaction_date) AS month,
        t.transaction_type,
        COUNT(t.id) AS transaction_count,
        SUM(t.amount) AS total_volume,
        SUM(t.amount * t.commission_rate) AS commission_earned
    FROM transactions t
    WHERE t.transaction_date >= '2026-01-01'
    GROUP BY DATE_TRUNC('month', t.transaction_date), t.transaction_type
),
monthly_summary AS (
    SELECT 
        month,
        SUM(CASE WHEN transaction_type = 'payment' THEN total_volume ELSE 0 END) AS gross_volume,
        SUM(CASE WHEN transaction_type = 'refund' THEN total_volume ELSE 0 END) AS refund_volume,
        SUM(CASE WHEN transaction_type = 'chargeback' THEN total_volume ELSE 0 END) AS chargeback_volume,
        SUM(CASE WHEN transaction_type = 'payment' THEN commission_earned ELSE 0 END) AS gross_commission,
        SUM(CASE WHEN transaction_type = 'refund' THEN commission_earned ELSE 0 END) AS lost_commission_refunds,
        SUM(CASE WHEN transaction_type = 'chargeback' THEN commission_earned ELSE 0 END) AS lost_commission_chargebacks
    FROM monthly_financials
    GROUP BY month
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') AS month_label,
    ROUND(gross_volume, 2) AS gross_revenue,
    ROUND(refund_volume, 2) AS refunds,
    ROUND(chargeback_volume, 2) AS chargebacks,
    ROUND(gross_volume - refund_volume - chargeback_volume, 2) AS net_revenue,
    ROUND(gross_commission, 2) AS gross_commission,
    ROUND(gross_commission - lost_commission_refunds - lost_commission_chargebacks, 2) AS net_commission,
    ROUND(
        (gross_commission - lost_commission_refunds - lost_commission_chargebacks) / 
        NULLIF(gross_volume - refund_volume - chargeback_volume, 0) * 100, 
        2
    ) AS effective_commission_rate_pct
FROM monthly_summary
ORDER BY month;


-- QUERY 2: Channel Performance Analysis (Using CTE & Window Functions)
-- Ranks acquisition channels by revenue contribution and signup velocity
-- ============================================
WITH channel_merchants AS (
    SELECT 
        m.channel,
        COUNT(DISTINCT m.id) AS total_merchants,
        COUNT(DISTINCT CASE WHEN m.status = 'Active' THEN m.id END) AS active_merchants,
        COUNT(DISTINCT CASE WHEN m.status = 'Churned' THEN m.id END) AS churned_merchants
    FROM merchants m
    GROUP BY m.channel
),
channel_transactions AS (
    SELECT 
        m.channel,
        COUNT(t.id) AS total_transactions,
        SUM(t.amount) AS total_volume,
        SUM(t.amount * t.commission_rate) AS total_commission,
        ROUND(AVG(t.amount), 2) AS avg_transaction_value
    FROM transactions t
    JOIN merchants m ON t.merchant_id = m.id
    WHERE t.transaction_type = 'payment'
    GROUP BY m.channel
),
channel_monthly_signups AS (
    SELECT 
        channel,
        DATE_TRUNC('month', signup_date) AS signup_month,
        COUNT(id) AS new_signups
    FROM merchants
    GROUP BY channel, DATE_TRUNC('month', signup_date)
)
SELECT 
    cm.channel,
    cm.total_merchants,
    cm.active_merchants,
    cm.churned_merchants,
    ROUND(cm.churned_merchants::DECIMAL / NULLIF(cm.total_merchants, 0) * 100, 1) AS churn_rate_pct,
    ct.total_transactions,
    ROUND(ct.total_volume, 2) AS total_payment_volume,
    ROUND(ct.total_commission, 2) AS total_commission_earned,
    ct.avg_transaction_value,
    ROUND(ct.total_volume / NULLIF(cm.active_merchants, 0), 2) AS revenue_per_active_merchant,
    -- Window function: Rank channels by total volume
    RANK() OVER (ORDER BY ct.total_volume DESC) AS volume_rank,
    -- Window function: Rank by average transaction value
    RANK() OVER (ORDER BY ct.avg_transaction_value DESC) AS atv_rank,
    -- Percentage of total revenue
    ROUND(ct.total_volume / SUM(ct.total_volume) OVER () * 100, 1) AS volume_share_pct
FROM channel_merchants cm
LEFT JOIN channel_transactions ct ON cm.channel = ct.channel
ORDER BY ct.total_volume DESC NULLS LAST;


-- QUERY 3: Monthly Churn Rate Analysis
-- Tracks merchant status changes over time
-- ============================================
WITH monthly_active_base AS (
    SELECT 
        DATE_TRUNC('month', generate_series('2026-01-01'::DATE, '2026-04-30'::DATE, '1 month'::INTERVAL)) AS analysis_month
),
active_merchants_by_month AS (
    SELECT 
        mab.analysis_month,
        COUNT(DISTINCT m.id) AS starting_active_merchants,
        COUNT(DISTINCT CASE 
            WHEN m.status = 'Churned' AND m.signup_date <= mab.analysis_month 
            THEN m.id 
        END) AS cumulative_churned
    FROM monthly_active_base mab
    CROSS JOIN merchants m
    WHERE m.signup_date <= mab.analysis_month
    GROUP BY mab.analysis_month
),
new_signups AS (
    SELECT 
        DATE_TRUNC('month', signup_date) AS signup_month,
        COUNT(id) AS new_merchants
    FROM merchants
    GROUP BY DATE_TRUNC('month', signup_date)
)
SELECT 
    TO_CHAR(amb.analysis_month, 'YYYY-MM') AS month,
    amb.starting_active_merchants - amb.cumulative_churned AS active_merchants,
    amb.cumulative_churned AS churned_merchants,
    COALESCE(ns.new_merchants, 0) AS new_signups,
    ROUND(
        amb.cumulative_churned::DECIMAL / NULLIF(amb.starting_active_merchants, 0) * 100, 
        1
    ) AS cumulative_churn_rate_pct,
    -- Calculate net merchant growth
    COALESCE(ns.new_merchants, 0) - 
    (amb.cumulative_churned - COALESCE(LAG(amb.cumulative_churned) OVER (ORDER BY amb.analysis_month), 0)) 
    AS net_merchant_change
FROM active_merchants_by_month amb
LEFT JOIN new_signups ns ON amb.analysis_month = ns.signup_month
ORDER BY amb.analysis_month;


-- QUERY 4: Top Performing Merchants (For Deep-Dive Analysis)
-- Identifies highest revenue merchants and their concentration risk
-- ============================================
WITH merchant_revenue AS (
    SELECT 
        m.id,
        m.name,
        m.channel,
        m.business_type,
        m.signup_date,
        COUNT(t.id) AS transaction_count,
        SUM(t.amount) AS total_volume,
        SUM(t.amount * t.commission_rate) AS total_commission,
        ROUND(AVG(t.amount), 2) AS avg_transaction_value,
        MIN(t.transaction_date) AS first_transaction,
        MAX(t.transaction_date) AS last_transaction
    FROM merchants m
    JOIN transactions t ON m.id = t.merchant_id
    WHERE t.transaction_type = 'payment'
        AND m.status = 'Active'
    GROUP BY m.id, m.name, m.channel, m.business_type, m.signup_date
)
SELECT 
    name,
    channel,
    business_type,
    transaction_count,
    ROUND(total_volume, 2) AS total_revenue,
    ROUND(total_commission, 2) AS commission_generated,
    avg_transaction_value,
    -- Running total for concentration analysis
    ROUND(SUM(total_volume) OVER (ORDER BY total_volume DESC) / 
          SUM(total_volume) OVER () * 100, 1) AS cumulative_revenue_pct,
    -- Rank by revenue
    ROW_NUMBER() OVER (ORDER BY total_volume DESC) AS revenue_rank,
    -- Days since last transaction
    (DATE '2026-04-30' - last_transaction::DATE) AS days_since_last_transaction
FROM merchant_revenue
ORDER BY total_volume DESC
LIMIT 20;


-- QUERY 5: Revenue Leakage Detection
-- Identifies potential issues: high refund rates, inactive merchants, chargeback patterns
-- ============================================
WITH merchant_health AS (
    SELECT 
        m.id,
        m.name,
        m.channel,
        m.status,
        COUNT(t.id) AS total_transactions,
        SUM(CASE WHEN t.transaction_type = 'payment' THEN 1 ELSE 0 END) AS payment_count,
        SUM(CASE WHEN t.transaction_type = 'refund' THEN 1 ELSE 0 END) AS refund_count,
        SUM(CASE WHEN t.transaction_type = 'chargeback' THEN 1 ELSE 0 END) AS chargeback_count,
        SUM(CASE WHEN t.transaction_type = 'payment' THEN t.amount ELSE 0 END) AS total_revenue,
        SUM(CASE WHEN t.transaction_type = 'refund' THEN t.amount ELSE 0 END) AS total_refunds,
        MAX(t.transaction_date) AS last_activity_date
    FROM merchants m
    LEFT JOIN transactions t ON m.id = t.merchant_id
    GROUP BY m.id, m.name, m.channel, m.status
)
SELECT 
    name,
    channel,
    status,
    total_transactions,
    payment_count,
    refund_count,
    chargeback_count,
    ROUND(total_revenue, 2) AS revenue,
    ROUND(total_refunds, 2) AS refunds,
    -- Flag high-risk merchants
    CASE 
        WHEN refund_count::DECIMAL / NULLIF(payment_count, 0) > 0.15 THEN 'HIGH REFUND RATE'
        WHEN chargeback_count > 0 THEN 'CHARGEBACK RISK'
        WHEN status = 'Active' AND last_activity_date < '2026-03-01' THEN 'INACTIVE - AT RISK'
        WHEN status = 'Active' AND last_activity_date IS NULL THEN 'NO TRANSACTIONS'
        ELSE 'HEALTHY'
    END AS risk_flag,
    ROUND(refund_count::DECIMAL / NULLIF(payment_count, 0) * 100, 1) AS refund_rate_pct
FROM merchant_health
WHERE risk_flag != 'HEALTHY'
    OR status = 'Churned'
ORDER BY 
    CASE risk_flag
        WHEN 'HIGH REFUND RATE' THEN 1
        WHEN 'CHARGEBACK RISK' THEN 2
        WHEN 'INACTIVE - AT RISK' THEN 3
        WHEN 'NO TRANSACTIONS' THEN 4
        ELSE 5
    END;
