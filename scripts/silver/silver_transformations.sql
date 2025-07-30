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


