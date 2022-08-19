sp_findtab tbl_CS_RAW_Paylocity_Userlist
sp_findcode [dbp_cs_load_paylocity_data]
--CONVERTCSV 
CREATE TABLE dbo.redacted
(
	rowLevel INT,
	employeeID INT,
	employeeStatus VARCHAR(MAX),
	hireDate VARCHAR(MAX),
	termDate VARCHAR(MAX),
	rehireDate VARCHAR(MAX),
	jobTitleCode VARCHAR(MAX),
	jobTitleName VARCHAR(MAX),
	depCode VARCHAR(MAX),
	depName VARCHAR(MAX),
	eMail VARCHAR(MAX),
	NTID VARCHAR(MAX),
	paycomID VARCHAR(MAX),
	lastName VARCHAR(MAX),
	firstName VARCHAR(MAX),
	middleName VARCHAR(MAX),
	nameID VARCHAR(MAX),
	SSN4 INT,
	DISTRICT VARCHAR(MAX),
	REGION VARCHAR(MAX),
	AREA VARCHAR(MAX)
)


BULK INSERT dbo.redacted
FROM (
SELECT files_name
FROM tbl_cs_tmo_files_upload 
WHERE files_name like 'Paylocity_User_List_07052022.csv'
) 
WITH 
( 
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
)
GO

ALTER TABLE redacted_table
ADD SSN4 VARCHAR(10);