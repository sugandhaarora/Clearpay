-- ClearPay AML Validation Queries
-- Author: Sugandha Arora
-- Purpose: Validate transaction integrity and AML detection logic
-- Note: Designed for use against synthetic test data only. No real PII.

-- ============================================================
-- SCHEMA REFERENCE
-- users: user_id, name, kyc_status, pep_flag, sanctions_flag, 
--        created_at, last_active_at
-- transactions: txn_id, sender_id, recipient_id, amount, 
--               type, status, jurisdiction, created_at
-- aml_alerts: alert_id, user_id, txn_id, alert_type, 
--             status, review_notes, created_at
-- ============================================================


-- Query 1: Structuring detection
-- Identifies users with cumulative transfers between $9000 and $10000
-- within a 24-hour window — classic structuring pattern to avoid FINTRAC LCTR
SELECT 
    sender_id,
    SUM(amount) AS cumulative_amount,
    COUNT(*) AS transfer_count,
    MIN(created_at) AS window_start,
    MAX(created_at) AS window_end
FROM transactions
WHERE 
    type = 'e-transfer'
    AND status = 'completed'
    AND created_at >= NOW() - INTERVAL '24 hours'
GROUP BY sender_id
HAVING SUM(amount) BETWEEN 9000 AND 9999.99
ORDER BY cumulative_amount DESC;


-- Query 2: FINTRAC large transaction threshold validation
-- Confirms all transactions at or above $10000 have a corresponding AML alert
-- Any row returned here is a compliance gap
SELECT 
    t.txn_id,
    t.sender_id,
    t.amount,
    t.created_at,
    a.alert_id,
    a.alert_type
FROM transactions t
LEFT JOIN aml_alerts a 
    ON t.txn_id = a.txn_id 
    AND a.alert_type = 'LCTR'
WHERE 
    t.amount >= 10000
    AND t.status = 'completed'
    AND a.alert_id IS NULL;


-- Query 3: PEP users who transacted without enhanced due diligence flag
-- Identifies compliance gap where PEP-flagged users are transacting normally
SELECT 
    u.user_id,
    u.name,
    u.pep_flag,
    t.txn_id,
    t.amount,
    t.created_at
FROM users u
JOIN transactions t ON u.user_id = t.sender_id
WHERE 
    u.pep_flag = TRUE
    AND t.status = 'completed'
    AND NOT EXISTS (
        SELECT 1 FROM aml_alerts a 
        WHERE a.user_id = u.user_id 
        AND a.alert_type = 'PEP_REVIEW'
    );


-- Query 4: Sanctions screening gap
-- Identifies users with sanctions flag who successfully completed transactions
-- Any row returned is a critical compliance failure
SELECT 
    u.user_id,
    u.name,
    u.sanctions_flag,
    t.txn_id,
    t.amount,
    t.created_at
FROM users u
JOIN transactions t ON u.user_id = t.sender_id
WHERE 
    u.sanctions_flag = TRUE
    AND t.status = 'completed';


-- Query 5: Dormant account activity detection
-- Flags accounts inactive for 90+ days that initiated transfers over $1000
-- Validates REQ-AML-04 dormant account monitoring rule
SELECT 
    u.user_id,
    u.name,
    u.last_active_at,
    t.txn_id,
    t.amount,
    t.created_at,
    DATEDIFF(t.created_at, u.last_active_at) AS days_inactive
FROM users u
JOIN transactions t ON u.user_id = t.sender_id
WHERE 
    DATEDIFF(t.created_at, u.last_active_at) >= 90
    AND t.amount > 1000
    AND t.status = 'completed'
ORDER BY days_inactive DESC;


-- Query 6: Round-number transaction velocity detection
-- Identifies users sending 3 or more round-number transfers within 1 hour
-- Round numbers (no cents) are a known AML pattern indicator
SELECT 
    sender_id,
    COUNT(*) AS round_txn_count,
    SUM(amount) AS total_amount,
    MIN(created_at) AS window_start,
    MAX(created_at) AS window_end
FROM transactions
WHERE 
    amount = FLOOR(amount)
    AND type = 'e-transfer'
    AND status = 'completed'
    AND created_at >= NOW() - INTERVAL '1 hour'
GROUP BY sender_id
HAVING COUNT(*) >= 3
ORDER BY round_txn_count DESC;


-- Query 7: High-risk jurisdiction transfers without alert
-- Validates that transfers to FATF high-risk jurisdictions triggered an alert
-- Any row returned indicates a monitoring gap
SELECT 
    t.txn_id,
    t.sender_id,
    t.recipient_id,
    t.amount,
    t.jurisdiction,
    t.created_at,
    a.alert_id
FROM transactions t
LEFT JOIN aml_alerts a 
    ON t.txn_id = a.txn_id 
    AND a.alert_type = 'HIGH_RISK_JURISDICTION'
WHERE 
    t.jurisdiction IN ('IR', 'KP', 'MM', 'SY', 'YE')
    AND t.status = 'completed'
    AND a.alert_id IS NULL;


-- Query 8: AML alerts closed without review notes
-- Validates REQ-AML-08 — alert closure must include documented reason
-- Any row returned is a process compliance failure
SELECT 
    alert_id,
    user_id,
    txn_id,
    alert_type,
    status,
    review_notes,
    created_at
FROM aml_alerts
WHERE 
    status = 'closed'
    AND (review_notes IS NULL OR TRIM(review_notes) = '');


-- Query 9: Suspicious transaction report coverage check
-- Confirms all transactions flagged as suspicious have a corresponding STR record
-- Any row returned means an STR was not generated for a flagged transaction
SELECT 
    a.alert_id,
    a.user_id,
    a.txn_id,
    a.alert_type,
    a.created_at,
    s.str_id
FROM aml_alerts a
LEFT JOIN suspicious_transaction_reports s 
    ON a.txn_id = s.txn_id
WHERE 
    a.alert_type = 'SUSPICIOUS_ACTIVITY'
    AND s.str_id IS NULL;


-- Query 10: Overall AML alert coverage summary
-- Provides a count of each alert type raised in the current test cycle
-- Use this to verify all expected alert types were triggered during testing
SELECT 
    alert_type,
    COUNT(*) AS total_alerts,
    SUM(CASE WHEN status = 'open' THEN 1 ELSE 0 END) AS open_alerts,
    SUM(CASE WHEN status = 'closed' THEN 1 ELSE 0 END) AS closed_alerts,
    SUM(CASE WHEN status = 'closed' AND (review_notes IS NULL OR TRIM(review_notes) = '') THEN 1 ELSE 0 END) AS closed_without_notes
FROM aml_alerts
GROUP BY alert_type
ORDER BY total_alerts DESC;
