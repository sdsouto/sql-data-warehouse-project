-- Check that no duplicates were introduced from joins
-- Expected result: No Records
SELECT cst_id, count(*) FROM (
SELECT 
    ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,
    ci.cst_gndr,
    ci.cst_create_date,
    ca.bdate,
    ca.gen,
    cl.cntry
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 cl
ON ci.cst_key = cl.cid) as t
GROUP BY cst_id
HAVING COUNT(*) > 1


-- Check lower-level Data Integrations
SELECT DISTINCT
    ci.cst_gndr,
    ca.gen,
    CASE WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr --CRM is the Master for gender info
        ELSE COALESCE(ca.gen, 'n/a') -- else if CRM is n/a then instead get from ERP, unless ERP is missing (NULL), then just use the n/a
    END AS new_gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 cl
ON ci.cst_key = cl.cid
ORDER BY 1,2

SELECT DISTINCT gender
FROM gold.dim_customers

--product


-- Check Uniqueness in join
-- Expectation: No Results
SELECT prd_id, COUNT(*) FROM (
SELECT 
    pr.prd_id,
    pr.cat_id,
    pr.prd_key,
    pr.prd_nm,
    pr.prd_cost,
    pr.prd_line,
    pc.cat,
    pc.subcat,
    pc.maintenance,
    pr.prd_start_dt
FROM silver.crm_prd_info pr
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pr.cat_id = pc.id
WHERE pr.prd_end_dt IS NULL --Filter out all historical data
) AS t GROUP BY prd_id --Check uniqueness to prd_id since it is used to join to sales
HAVING COUNT(*) > 1

SELECT *
FROM gold.dim_products

-- Foreign Key Integrity (Dimension)
SELECT * 
FROM gold.fact_sales sa
LEFT JOIN gold.dim_customers cu
ON sa.customer_key = cu.customer_key
LEFT JOIN gold.dim_products pr
ON sa.product_key = pr.product_key
WHERE cu.customer_key IS NULL OR pr.product_key IS NULL

