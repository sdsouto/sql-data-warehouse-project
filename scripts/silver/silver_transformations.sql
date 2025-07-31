USE [DataWarehouse]
GO

--TRUNCATE TABLE silver.crm_cust_info

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


--TRUNCATE TABLE silver.crm_prd_info
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
    REPLACE(SUBSTRING(prd_key, 7, len(prd_key)),'-','_') AS prd_key, --Derive product key
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
GO



