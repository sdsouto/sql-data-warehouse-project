-- Check for Nulls or Duplicates in Primary Key
-- Expectation: No Results

SELECT cst_id, count(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces in string values.
-- Expection: No Results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname <> TRIM(cst_lastname)

-- Data Stanardization & Consistemcy
-- Check for consistency within low cardinality columns
SELECT DISTINCT(cst_marital_status)
FROM silver.crm_cust_info

SELECT DISTINCT(cst_gndr)
FROM silver.crm_cust_info


select * from silver.crm_cust_info

