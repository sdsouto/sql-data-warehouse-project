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


--check for invalid dates:
select cst_create_date, isdate(cst_create_date)
from bronze.crm_cust_info

--should be none, but there are three in bronze which are removed in silver due to cst_id being null
select *
from bronze.crm_cust_info
where cst_create_date is null

select * from bronze.crm_cust_info
where cst_key in(
'SF566',
'PO25',
'13451235')

select * from silver.crm_cust_info

