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