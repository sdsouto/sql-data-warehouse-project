USE [DataWarehouse]
GO

PRINT '>> Truncating, Loading Table: silver.crm_cust_info'
TRUNCATE TABLE silver.crm_cust_info

INSERT INTO silver.crm_cust_info (
		    cst_id, 
		    cst_key, 
		    cst_firstname, 
		    cst_lastname, 
		    cst_marital_status, 
		    cst_gndr,
		    cst_create_date
        )
        SELECT  
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' --Trim to remove unwanted spaces and ensure data consistency and uniformity across all records
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a' -- Handling missing data by filling in blanks by adding a default value
             END cst_marital_status, -- Data Normalization & Standardization to map coded values to meaningful, user-friendly descriptions
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
             END cst_gndr,
            cst_create_date
        FROM (
            SELECT 
                *
                ,ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
            ) AS t
        WHERE flag_last = 1 -- Remove duplicates to ensure only one record per entity by identifying and retaining the most relevant row

PRINT '>> Truncating, Loading Table: silver.crm_prd_info'
TRUNCATE TABLE silver.crm_prd_info
INSERT INTO [silver].[crm_prd_info]
    ([prd_id]
    ,[cat_id]
    ,[prd_key]
    ,[prd_nm]
    ,[prd_cost]
    ,[prd_line]
    ,[prd_start_dt]
    ,[prd_end_dt])
SELECT 
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5),'-','_') AS cat_id, --Derive category id
    SUBSTRING(prd_key, 7, len(prd_key)) AS prd_key, --Derive product key
    prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost,
    CASE UPPER(TRIM(prd_line))
	    WHEN 'M' THEN 'Mountain'
	    WHEN 'R' THEN 'Road'
	    WHEN 'S' THEN 'Other Sales'
	    WHEN 'T' THEN 'Touring'
	    ELSE 'n/a' --Handling missing data by filling in blanks by adding a default value
    END AS prd_line, --Data Normalization & Standardization to map product line codes to descriptive values
    CAST(prd_start_dt AS DATE) AS prd_start_dt, --Data Transformation: Remove time from date
    CAST(
        LEAD(CAST(prd_start_dt AS DATETIME)) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 
        AS DATE
    ) AS prd_end_dt -- Data Enrichment: Calculate end date as one day before the next start date and present without time
FROM bronze.crm_prd_info

PRINT '>> Truncating, Loading Table: silver.crm_sales_details'
TRUNCATE TABLE silver.crm_sales_details
INSERT INTO silver.crm_sales_details
           (
           sls_ord_num
           ,sls_prd_key
           ,sls_cust_id
           ,sls_order_dt
           ,sls_ship_dt
           ,sls_due_dt
           ,sls_sales
           ,sls_quantity
           ,sls_price
)
SELECT 
    sls_ord_num
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
	 CASE  WHEN sls_sales IS NULL or sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
	       THEN sls_quantity * ABS(sls_price)
	       ELSE sls_sales
     END AS sls_sales, -- Recalculate sales if original value is missing or incorrect
    sls_quantity,
    CASE   WHEN sls_price IS NULL or SLS_price <=0
	       THEN sls_sales / NULLIF(sls_quantity,0)
	       ELSE sls_price
    END as sls_price -- Derive price if original value is invalid
  FROM bronze.crm_sales_details

PRINT '>> Truncating, Loading Table: silver.erp_cust_az12'
TRUNCATE TABLE silver.erp_cust_az12
INSERT INTO silver.erp_cust_az12
  (cid, bdate, gen)
SELECT
	CASE WHEN cid like 'NAS%' 
		THEN SUBSTRING(cid,4,len(cid))
		ELSE cid
	END as cid, -- Remove 'NAS' prefix if present
	CASE WHEN bdate < '1900-01-01' OR bdate > GETDATE()
		THEN NULL
		ELSE bdate
	END AS bdate, -- Set very old and future birthdates to NULL
    CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen))  IN ('M','MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen  -- Normalize gender values and handle unknown cases
FROM bronze.erp_cust_az12


PRINT '>> Truncating, Loading Table: silver.erp_loc_a101'
TRUNCATE TABLE silver.erp_loc_a101
INSERT INTO silver.erp_loc_a101
(cid, cntry)
SELECT
REPLACE(cid,'-','') as cid, -- Remove invalid values to match key to other tables
CASE WHEN TRIM(cntry) IN ('DE') THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry) --Normalize and Handle missing or blank country codes and replace with friendly values
END AS cntry
FROM bronze.erp_loc_a101


PRINT '>> Truncating, Loading Table: silver.erp_px_cat_g1v2'
TRUNCATE TABLE silver.erp_px_cat_g1v2
INSERT INTO silver.erp_px_cat_g1v2
(id, cat, subcat, maintenance)
SELECT
     id
    ,cat
    ,subcat
    ,maintenance
FROM bronze.erp_px_cat_g1v2