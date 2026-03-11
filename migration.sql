BEGIN;

-- 1. Add merchant_id column
ALTER TABLE transactions
ADD COLUMN merchant_id BIGINT;

-- 2. Insert missing merchants from transactions
-- Apply exact normalization to merchant_normalized
INSERT INTO merchant_mcc_cache (
    merchant_normalized,
    merchant_original,
    mcc_code,
    mcc_description
)
SELECT DISTINCT
    trim(regexp_replace(replace(upper(merchant), ' ', ''), '[^A-Z0-9]', '', 'g')) AS merchant_normalized,
    merchant AS merchant_original,
    mcc_code,
    category AS mcc_description
FROM transactions t
WHERE merchant IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM merchant_mcc_cache m
    WHERE m.merchant_original = t.merchant
);

-- 3. Map transactions → merchant_id based on exact merchant_original
UPDATE transactions t
SET merchant_id = m.id
FROM merchant_mcc_cache m
WHERE t.merchant = m.merchant_original;

-- 4. Create index for fast joins
CREATE INDEX IF NOT EXISTS idx_transactions_merchant_id
ON transactions(merchant_id);

-- 5. Add foreign key constraint
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_merchant
FOREIGN KEY (merchant_id)
REFERENCES merchant_mcc_cache(id);

COMMIT;
