/*=================================================
crm_cust_info
=================================================*/
--select * from bronze.crm_cust_info


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
SUBSTRING(prd_key, 7, len(prd_key)) AS prd_key,
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
SUBSTRING(prd_key, 7, len(prd_key)) AS prd_key
FROM bronze.crm_prd_info

--There are many that do not match.  The key looks correct.  Therefore, this means that there are products with no orders.
select * from  bronze.crm_prd_info
where SUBSTRING(prd_key, 7, len(prd_key)) not in (select sls_prd_key
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








/*=================================================
crm_sales_details
=================================================*/
--select * from bronze.crm_sales_details

USE DataWarehouse
GO

SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
	 ,CASE	WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8
			THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	  END AS sls_order_dt
	 ,CASE	WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8
			THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	  END AS sls_ship_dt
	 ,CASE	WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8
			THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	  END AS sls_due_dt,
	  CASE WHEN sls_sales IS NULL or sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL or SLS_price <=0
	THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END as sls_price
  FROM bronze.crm_sales_details

-- Check for unwanted spaces in string values, lowercase
-- Expection: No Results
SELECT 
	sls_ord_num
FROM bronze.crm_sales_details
WHERE TRIM(UPPER(sls_ord_num)) <> sls_ord_num

-- Check that the keys would join
-- Using transformed silver, there should be no exceptions
SELECT 
sls_prd_key
FROM bronze.crm_sales_details 
--WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)

SELECT 
sls_prd_key
FROM silver.crm_sales_details 
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)
--WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)



-- Data Stanardization & Consistemcy 
-- >> Sales = Qualtity * Price
-- >> Values must not be NULL, zero, or negative
-- Business Rules:
-- >> If Sales is negative, zero, or null, derive it using Quantity and Price
-- >> If Price is zero or null, calculate it using Sales and Quantity
-- >> If Price is negative, convert it to a positive value

SELECT DISTINCT
sls_sales AS sls_sales_old,
sls_quantity AS sls_quantity_old,
sls_price AS sls_price_old,
CASE WHEN sls_sales IS NULL or sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL or SLS_price <=0
	THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END as sls_price
FROM bronze.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

SELECT *
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY
sls_sales, sls_quantity, sls_price

SELECT *
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY
sls_sales, sls_quantity, sls_price


-- Check for invalid dates
-- Expectation: all integers to be converted to date
-- sls_order_dt: 0,5489,32154
SELECT 
  --    distinct(sls_order_dt)
	 --, nullif(sls_order_dt,0)
	 CASE	WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8
			THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	 END AS sls_order_dt
	 ,CASE	WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8
			THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	 END AS sls_ship_dt
	 ,CASE	WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8
			THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	 END AS sls_due_dt
  FROM bronze.crm_sales_details
  WHERE 
  sls_order_dt <=0
  OR LEN(sls_order_dt) <> 8
  OR sls_order_dt > 20500101
  OR sls_order_dt < 190001
  OR CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) > CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) -- Order Date must always be earlier than the shipping date, due date
  OR CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) > CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) -- Order Date must always be earlier than the shipping date, due date
  ORDER BY sls_order_dt

SELECT sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE 
  sls_order_dt  > sls_ship_dt -- Order Date must always be earlier than the shipping date, due date
  OR sls_order_dt > sls_due_dt -- Order Date must always be earlier than the shipping date, due date

--select * from silver.crm_sales_details



/*=================================================
erp_cust_az12
=================================================*/
SELECT
	CASE WHEN cid like 'NAS%' 
		THEN SUBSTRING(cid,4,len(cid))
		ELSE cid
	END as cid,
	CASE WHEN bdate < '1900-01-01' OR bdate > GETDATE()
		THEN NULL
		ELSE bdate
	END AS bdate,
    CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen))  IN ('M','MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12

-- Check
-- Expectation: No results
SELECT
	CASE WHEN cid like 'NAS%' 
		THEN SUBSTRING(cid,4,len(cid))
		ELSE cid
	END as cid
      ,bdate
      ,gen
FROM bronze.erp_cust_az12
where CASE WHEN cid like 'NAS%' 
	THEN SUBSTRING(cid,4,len(cid))
	ELSE cid
END NOT IN (select cst_key from silver.crm_cust_info)

-- Check for incorrect dates
-- Date is date, so check out of range

SELECT bdate
FROM bronze.erp_cust_az12
where bdate < '1900-01-01' OR bdate > GETDATE()

SELECT bdate
FROM silver.erp_cust_az12
where bdate < '1900-01-01' OR bdate > GETDATE()


--Data Standardization & Consistency
--Check low cardinality, distinct values
SELECT DISTINCT
gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen))  IN ('M','MALE') THEN 'Male'
	ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12

SELECT DISTINCT
gen
FROM silver.erp_cust_az12

SELECT *
FROM silver.erp_cust_az12


/*=================================================
erp_loc_a101
=================================================*/
select * from bronze.erp_loc_a101

SELECT
REPLACE(cid,'-','') as cid,
CASE WHEN TRIM(cntry) IN ('DE') THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101

select cst_key from silver.crm_cust_info
select REPLACE(cid,'-','') from bronze.erp_loc_a101

--check join
-- Expectation: No results
SELECT *
 from bronze.erp_loc_a101
WHERE REPLACE(cid,'-','') NOT IN (select cst_key from silver.crm_cust_info)

SELECT *
 from silver.erp_loc_a101
WHERE cid NOT IN (select cst_key from silver.crm_cust_info)

--Check low cardinality
SELECT DISTINCT(cntry)
FROM bronze.erp_loc_a101 
ORDER BY cntry

SELECT
DISTINCT
cntry as cntry_old,
CASE WHEN TRIM(cntry) IN ('DE') THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101

SELECT DISTINCT(cntry)
FROM silver.erp_loc_a101 
ORDER BY cntry

SELECT *
FROM silver.erp_loc_a101 


/*=================================================
erp_px_cat_g1v2
=================================================*/

SELECT * FROM bronze.erp_px_cat_g1v2

--Check Join for key column
-- One id is missing, this means the cat_id is not in the category table.  Join is good.
select id from bronze.erp_px_cat_g1v2
where id not in (
select cat_id from silver.crm_prd_info)

select id from silver.erp_px_cat_g1v2
where id not in (
select cat_id from silver.crm_prd_info)

-- Check for unwanted spaces
-- Expected result: No results
SELECT
*
FROM bronze.erp_px_cat_g1v2
WHERE cat <> TRIM(cat) OR subcat <> TRIM(subcat) OR maintenance <> TRIM(maintenance)

SELECT
*
FROM silver.erp_px_cat_g1v2
WHERE cat <> TRIM(cat) OR subcat <> TRIM(subcat) OR maintenance <> TRIM(maintenance)


-- Data Standardization & Consistency
SELECT DISTINCT
cat
FROM bronze.erp_px_cat_g1v2

SELECT * FROM silver.erp_px_cat_g1v2
