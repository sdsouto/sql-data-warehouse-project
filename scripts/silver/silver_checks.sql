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

/*=================================================
crm_prd_info
=================================================*/
--select * from bronze.crm_prd_info
SELECT 
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5),'-','_') AS cat_id,
REPLACE(SUBSTRING(prd_key, 7, len(prd_key)),'-','_') AS prd_key,
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	ELSE 'n/a' END AS prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(CAST(prd_start_dt AS DATETIME)) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info


-- Check for Nulls or Duplicates in Primary Key
-- Expectation: No Results
select prd_id, count(*)
from silver.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null

--derive new key from crm_prd_info.prd_key to match erp_px_cat_g1v2.id
select prd_key
from silver.crm_prd_info
select id
from silver.erp_px_cat_g1v2

SELECT 
REPLACE(SUBSTRING(prd_key, 1, 5),'-','_') AS cat_id
FROM silver.crm_prd_info

--check the join
-- the transformation works, and there happens to be 7 rows not matching
select * from
(
SELECT 
REPLACE(SUBSTRING(prd_key, 1, 5),'-','_') AS cat_id
FROM bronze.crm_prd_info) as c join bronze.erp_px_cat_g1v2 e
on c.cat_id = e.id

select * from bronze.crm_prd_info
where REPLACE(SUBSTRING(prd_key, 1, 5),'-','_') 
not in (select id from  bronze.erp_px_cat_g1v2)



--derive new key from crm_prd_info.prd_key to match crm_sales_details.sls_prd_key
select prd_key
from bronze.crm_prd_info
select sls_prd_key
from bronze.crm_sales_details

SELECT 
REPLACE(SUBSTRING(prd_key, 7, len(prd_key)),'-','_') AS prd_key
FROM bronze.crm_prd_info

--There are many that do not match.  The key looks correct.  Therefore, this means that there are products with no orders.
select * from  bronze.crm_prd_info
where REPLACE(SUBSTRING(prd_key, 7, len(prd_key)),'-','_') not in (select sls_prd_key
from bronze.crm_sales_details)

-- Check for unwanted spaces in string values.
-- Expection: No Results
SELECT
prd_nm
FROM silver.crm_prd_info
WHERE TRIM(prd_nm) <> prd_nm OR prd_nm IS NULL

--Check for NULLs or Negative Numbers
--Expectation: No Results
SELECT
prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

SELECT
DISTINCT(prd_line),
CASE 
	WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
	WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'other sales'
	WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	ELSE 'n/a' END AS prd_line
FROM bronze.crm_prd_info

SELECT DISTINCT(prd_line) FROM silver.crm_prd_info

--Check for Invalid Dates
--There are invalid dates in end date
SELECT
DISTINCT(ISDATE(prd_start_dt)), prd_start_dt
--,
--DISTINCT(ISDATE(prd_end_dt)), prd_end_dt
FROM bronze.crm_prd_info

--Check for Incorrect Date Ordering
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

SELECT
prd_key,
prd_start_dt,
prd_end_dt,
LEAD(CAST(prd_start_dt AS DATETIME)) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS prd_end_dt_TEST
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509')
ORDER BY prd_id

SELECT * FROM silver.crm_prd_info