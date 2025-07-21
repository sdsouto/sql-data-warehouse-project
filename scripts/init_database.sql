/*
**************************************************************************************************
Script:			Create Database and Schemas
	
Description:	This script creates a new database named 'DataWarehouse' after checking if it already exists. 
                If the database exists, it is dropped and recreated.  Additionally, the script sets up three schemas 
                within the database: 'bronze', 'silver', and 'gold'.

Create Date:    2025-07-21

Used By:        SQL Data Warehouse Project

Usage:              

WARNING:        Running this script will drop the entire 'DataWarehouse' database if it exists. 
                All data in the database will be permanently deleted. Proceed with caution 
                and ensure you have proper backups before running this script.


History:
Date(yyyy-mmdd)		Author				Comments
------------------- ------------------- ----------------------------------------------------------
2025-0721			Sharon Souto		Initial Version

**************************************************************************************************
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
