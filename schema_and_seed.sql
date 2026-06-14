-- ============================================
-- MERCHANT PERFORMANCE ANALYTICS SCHEMA
-- ============================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Merchants Table
CREATE TABLE merchants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    business_type VARCHAR(100), -- e.g., 'Retail', 'Restaurant', 'SaaS', 'Service'
    signup_date DATE NOT NULL,
    channel VARCHAR(50) NOT NULL CHECK (channel IN ('Direct Sales', 'Digital', 'Agency', 'Partner Referral')),
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Churned', 'Suspended')),
    country VARCHAR(2) DEFAULT 'US',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Transactions Table
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    commission_rate DECIMAL(4, 3) NOT NULL DEFAULT 0.020, -- 2.0% default
    transaction_type VARCHAR(20) DEFAULT 'payment' CHECK (transaction_type IN ('payment', 'refund', 'chargeback')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create indexes for query performance
CREATE INDEX idx_merchants_channel ON merchants(channel);
CREATE INDEX idx_merchants_status ON merchants(status);
CREATE INDEX idx_merchants_signup_date ON merchants(signup_date);
CREATE INDEX idx_transactions_merchant_id ON transactions(merchant_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);

-- ============================================
-- SEED DATA: 50 Merchants
-- ============================================

INSERT INTO merchants (name, business_type, signup_date, channel, status, country) VALUES
-- Direct Sales (15 merchants)
('Coastal Coffee Roasters', 'Restaurant', '2025-01-15', 'Direct Sales', 'Active', 'US'),
('Metro Dental Associates', 'Healthcare', '2025-01-20', 'Direct Sales', 'Active', 'US'),
('Summit Outdoor Gear', 'Retail', '2025-01-22', 'Direct Sales', 'Active', 'US'),
('BlueSky Consulting Group', 'Service', '2025-02-01', 'Direct Sales', 'Active', 'US'),
('Golden Gate Fitness', 'Fitness', '2025-02-05', 'Direct Sales', 'Active', 'US'),
('Pacific Plumbing Co', 'Service', '2025-02-10', 'Direct Sales', 'Churned', 'US'),
('Evergreen Landscaping', 'Service', '2025-02-14', 'Direct Sales', 'Active', 'US'),
('Harbor View Hotel', 'Hospitality', '2025-02-18', 'Direct Sales', 'Active', 'US'),
('TechNova Solutions', 'SaaS', '2025-03-01', 'Direct Sales', 'Active', 'US'),
('Main Street Bakery', 'Restaurant', '2025-03-05', 'Direct Sales', 'Active', 'US'),
('Citywide Auto Repair', 'Service', '2025-03-10', 'Direct Sales', 'Churned', 'US'),
('Peak Performance Gym', 'Fitness', '2025-03-15', 'Direct Sales', 'Active', 'US'),
('Redwood Realty Group', 'Service', '2025-04-01', 'Direct Sales', 'Active', 'US'),
('Sunset Yoga Studio', 'Fitness', '2025-04-05', 'Direct Sales', 'Active', 'US'),
('Lakeside Marina', 'Retail', '2025-04-10', 'Direct Sales', 'Active', 'US'),

-- Digital Channel (15 merchants)
('QuickCart Express', 'Retail', '2025-01-10', 'Digital', 'Active', 'US'),
('CloudPeak Analytics', 'SaaS', '2025-01-12', 'Digital', 'Active', 'US'),
('FreshBite Meal Delivery', 'Service', '2025-01-18', 'Digital', 'Active', 'US'),
('PixelPerfect Design Co', 'Service', '2025-01-25', 'Digital', 'Active', 'US'),
('DataDriven Marketing', 'Service', '2025-02-03', 'Digital', 'Active', 'US'),
('SwiftShip Logistics', 'Service', '2025-02-08', 'Digital', 'Churned', 'US'),
('CodeCraft Academy', 'Education', '2025-02-12', 'Digital', 'Active', 'US'),
('StyleHub Fashion', 'Retail', '2025-02-20', 'Digital', 'Active', 'US'),
('GreenLeaf Organics', 'Retail', '2025-03-03', 'Digital', 'Active', 'US'),
('VirtualVault Security', 'SaaS', '2025-03-08', 'Digital', 'Active', 'US'),
('PetPal Supplies', 'Retail', '2025-03-14', 'Digital', 'Churned', 'US'),
('AudioStream Pro', 'SaaS', '2025-03-20', 'Digital', 'Active', 'US'),
('FitTrack Health', 'Fitness', '2025-04-02', 'Digital', 'Active', 'US'),
('LearnLoop Online', 'Education', '2025-04-08', 'Digital', 'Active', 'US'),
('BuzzSocial Media', 'Service', '2025-04-15', 'Digital', 'Active', 'US'),

-- Agency Channel (12 merchants)
('Elite Catering Services', 'Restaurant', '2025-01-08', 'Agency', 'Active', 'US'),
('Premier Tax Advisors', 'Service', '2025-01-28', 'Agency', 'Active', 'US'),
('Atlas Travel Agency', 'Service', '2025-02-06', 'Agency', 'Active', 'US'),
('Sterling Law Group', 'Service', '2025-02-15', 'Agency', 'Active', 'US'),
('NexGen Insurance', 'Service', '2025-02-22', 'Agency', 'Churned', 'US'),
('Artisan Craft Market', 'Retail', '2025-03-02', 'Agency', 'Active', 'US'),
('Vista Property Management', 'Service', '2025-03-12', 'Agency', 'Active', 'US'),
('Quantum Tech Labs', 'SaaS', '2025-03-18', 'Agency', 'Active', 'US'),
('Harmony Wellness Center', 'Healthcare', '2025-04-03', 'Agency', 'Active', 'US'),
('Capital Funding Corp', 'Service', '2025-04-09', 'Agency', 'Active', 'US'),
('BrightPath Education', 'Education', '2025-04-14', 'Agency', 'Active', 'US'),
('UrbanEats Food Truck', 'Restaurant', '2025-04-18', 'Agency', 'Active', 'US'),

-- Partner Referral (8 merchants)
('Compass Real Estate', 'Service', '2025-01-14', 'Partner Referral', 'Active', 'US'),
('Thrive Health Clinic', 'Healthcare', '2025-02-11', 'Partner Referral', 'Active', 'US'),
('Sierra Solar Energy', 'Service', '2025-03-06', 'Partner Referral', 'Active', 'US'),
('BrightBooks Accounting', 'Service', '2025-03-22', 'Partner Referral', 'Active', 'US'),
('ClearWater Filtration', 'Service', '2025-04-05', 'Partner Referral', 'Active', 'US'),
('Summit Legal Advisors', 'Service', '2025-04-12', 'Partner Referral', 'Churned', 'US'),
('FreshFields Produce', 'Retail', '2025-04-16', 'Partner Referral', 'Active', 'US'),
('MindfulMeds Pharmacy', 'Healthcare', '2025-04-20', 'Partner Referral', 'Active', 'US');

-- ============================================
-- SEED DATA: 500+ Transactions spanning Jan-Apr 2026
-- ============================================

-- Generate transactions using a series of inserts with randomized amounts
DO $$
DECLARE
    merchant_record RECORD;
    tx_count INT;
    base_amount DECIMAL(10,2);
    tx_date TIMESTAMPTZ;
    comm_rate DECIMAL(4,3);
BEGIN
    FOR merchant_record IN SELECT id, signup_date, business_type FROM merchants WHERE status = 'Active' LOOP
        -- Each active merchant gets 8-15 transactions spread across their active months
        tx_count := floor(random() * 8 + 8)::INT;
        
        FOR i IN 1..tx_count LOOP
            -- Random amount based on business type
            CASE merchant_record.business_type
                WHEN 'Restaurant' THEN base_amount := random() * 500 + 50;
                WHEN 'Retail' THEN base_amount := random() * 1000 + 100;
                WHEN 'SaaS' THEN base_amount := random() * 2000 + 500;
                WHEN 'Healthcare' THEN base_amount := random() * 800 + 150;
                WHEN 'Service' THEN base_amount := random() * 1500 + 200;
                WHEN 'Fitness' THEN base_amount := random() * 300 + 75;
                WHEN 'Hospitality' THEN base_amount := random() * 1200 + 300;
                WHEN 'Education' THEN base_amount := random() * 600 + 100;
                ELSE base_amount := random() * 400 + 100;
            END CASE;
            
            -- Date between signup and now (April 2026)
            tx_date := merchant_record.signup_date + (random() * (DATE '2026-04-30' - merchant_record.signup_date))::INT;
            
            -- Commission rate varies by channel (2% - 3.5%)
            comm_rate := 0.020 + (random() * 0.015);
            
            -- 90% chance of payment, 7% refund, 3% chargeback
            INSERT INTO transactions (merchant_id, transaction_date, amount, commission_rate, transaction_type)
            VALUES (
                merchant_record.id,
                tx_date,
                ROUND(base_amount::numeric, 2),
                ROUND(comm_rate::numeric, 3),
                CASE 
                    WHEN random() < 0.90 THEN 'payment'
                    WHEN random() < 0.97 THEN 'refund'
                    ELSE 'chargeback'
                END
            );
        END LOOP;
    END LOOP;
    
    -- Add some transactions for churned merchants (fewer, older)
    FOR merchant_record IN SELECT id, signup_date FROM merchants WHERE status = 'Churned' LOOP
        tx_count := floor(random() * 4 + 2)::INT;
        FOR i IN 1..tx_count LOOP
            base_amount := random() * 500 + 50;
            tx_date := merchant_record.signup_date + (random() * 60)::INT; -- Only first 2 months
            comm_rate := 0.020 + (random() * 0.010);
            
            INSERT INTO transactions (merchant_id, transaction_date, amount, commission_rate, transaction_type)
            VALUES (
                merchant_record.id,
                tx_date,
                ROUND(base_amount::numeric, 2),
                ROUND(comm_rate::numeric, 3),
                'payment'
            );
        END LOOP;
    END LOOP;
END $$;