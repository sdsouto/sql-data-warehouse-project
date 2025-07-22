SELECT TOP (1000) 'crm_cust_info' as source, * FROM bronze.crm_cust_info --customer information, cst_id and cst_key separate keys
SELECT TOP (1000) 'crm_prd_info' as source, * FROM bronze.crm_prd_info -- product information, historical.prd_key.
SELECT TOP (1000) 'crm_sales_details' as source, * FROM bronze.crm_sales_details --appears transactional. Sales and orders.  SLS_cust_id to erp_cust_info.cust_id, sls_prd_key to erp_prd_info.prd_key
SELECT TOP (1000) 'erp_cust_az12' as source, * FROM bronze.erp_cust_az12  --additional customer details(gender), bday, cid key looks mostly like cst_key from crm_cust_info 
SELECT TOP (1000) 'erp_loc_a101' as source, * FROM bronze.erp_loc_a101 --additional cust details, country.  CID key somewhat like cid in above table
SELECT TOP (1000) 'erp_px_cat_g1v2' as source, * FROM bronze.erp_px_cat_g1v2 -- product subcategories, id appears to be key
