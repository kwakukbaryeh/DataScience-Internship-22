--- SQL order of Execution --- 
--https://sqlbolt.com/lesson/select_queries_order_of_execution

--- SELECT ---
/* Using this table: redacted */

--1. Gather all store locations 

SELECT *
FROM redacted
GROUP BY Location;

--2. Gather all open store location

SELECT *
FROM redacted
WHERE status = 'Open';

--<> 
--= 
--NOT IN ('open','closed','omit')
--IN  ('open','closed','omit')
--Between 1 AND 2
--Between datetime and datetime2
--LIKE '%John'


--3. Gather all open store location in the state of Texas & Atlanta

SELECT *
FROM redacted
WHERE status = 'Open' and State IN ('TX', 'GA');

--4. Query a count of how many open store location in the state of Texas

SELECT Count(Location_Id) as Open_texas_stores
FROM redacted
WHERE status = 'Open' and State IN ('TX');

--5. Query a count of how many closed store location not in the state of Texas

SELECT Count(Location_Id) as Closed_texas_stores
FROM redacted
WHERE status = 'Closed' and State NOT IN ('TX');

--- Using this table: redacted 
--1. Find all employees with a last name starting with B 

SELECT * 
FROM redacted
WHERE [Last Name] LIKE 'B%'
ORDER BY [Last Name];

--2. Find all employees with a [Hire Date - Current] between July 2020 & Jan 2021

SELECT *
FROM redacted
WHERE CONVERT(datetime, [Hire Date - Current], 101) BETWEEN '2020-07-01' AND '2021-01-01'
ORDER BY 1;
SELECT getdate()
--ORDER BY CONVERT(datetime, [Hire Date - Current], 101);

--- JOIN ---
/* USING  redacted & redacted & redacted &
redacted */

--- Using JOIN
--1. Gather all store locations in Houston West and Arizona Northeast district

SELECT *
FROM redacted dim
JOIN redacted dim2 ON dim.store_district_id = dim2.store_district_id
WHERE dim2.district_name IN ('Houston West', 'Arizona Northeast');


--2. Gather all store locations in Ohio Valley Region

SELECT *
FROM redacted b2
INNER JOIN redacted b3 ON b2.store_region_id = b3.store_region_id
INNER JOIN redacted b1 ON b2.store_district_id = b1.store_district_id
WHERE b3.region_name IN ('Ohio Valley');


--3. Gather all store locations in West area

SELECT * 
FROM redacted lvl4
INNER JOIN redacted lvl3 ON lvl4.store_area_id = lvl3.store_area_id
INNER JOIN redacted lvl2 ON lvl3.store_region_id = lvl2.store_region_id
INNER JOIN redacted lvl1 ON lvl2.store_district_id = lvl1.store_district_id
WHERE lvl4.area_name IN ('West');

--- Using LEFT JOIN
--1. Gather all closed store locations that does not have an associated district

SELECT *
FROM redacted lvl1
LEFT JOIN redacted lvl2 ON lvl1.store_district_id = lvl2.store_district_id
WHERE lvl1.store_district_id IS NULL and lvl1.status IN ('Closed');

---  GROUP BY ---
/*Using tbl_cs_tmo_daily_statement & other tables mentioned*/
--Find total monthly_access by each stores & product_type & activation_type within North Central region for the month of March 2022. Sort by highest $ amount. 

SELECT SUM(monthly_access) total_monthly_access, region_name, Location, product_type, activation_type
FROM redacted lvl4
INNER JOIN redacted lvl3 ON lvl4.store_area_id = lvl3.store_area_id
INNER JOIN redacted lvl2 ON lvl3.store_region_id = lvl2.store_region_id
INNER JOIN redacted lvl1 ON lvl2.store_district_id = lvl1.store_district_id
INNER JOIN tbl_cs_tmo_daily_statement lvl0 ON lvl1.[SAP #]= lvl0.store_code
WHERE lvl3.region_name IN ('North Central') and CONVERT(datetime, lvl0.activation_date, 101) IN ('2020-03-01')
GROUP BY region_name, product_type, activation_type, Location
ORDER BY total_monthly_access DESC; 

--- temporary table & sub_query ---
-- INSERT ---
--Using the code written above, Insert the data into a temporary table using two methods SELECT INTO & INSERT INTO

SELECT SUM(monthly_access) total_monthly_access, region_name, Location
INTO #temp1_table
FROM redacted lvl4
INNER JOIN redacted lvl3 ON lvl4.store_area_id = lvl3.store_area_id
INNER JOIN redacted lvl2 ON lvl3.store_region_id = lvl2.store_region_id
INNER JOIN redacted lvl1 ON lvl2.store_district_id = lvl1.store_district_id
INNER JOIN tbl_cs_tmo_daily_statement lvl0 ON lvl1.[SAP #]= lvl0.store_code
WHERE lvl3.region_name IN ('North Central') and CONVERT(datetime, lvl0.activation_date, 101) IN ('2020-03-01')
GROUP BY region_name, Location
ORDER BY total_monthly_access DESC; 



SELECT lvl1.*
FROM redacted lvl4
INNER JOIN redacted lvl3 ON lvl4.store_area_id = lvl3.store_area_id
INNER JOIN redacted lvl2 ON lvl3.store_region_id = lvl2.store_region_id
INNER JOIN redacted lvl1 ON lvl2.store_district_id = lvl1.store_district_id
INNER JOIN tbl_cs_tmo_daily_statement lvl0 ON lvl1.[SAP #]= lvl0.store_code
WHERE lvl3.region_name IN ('North Central') and CONVERT(datetime, lvl0.activation_date, 101) IN ('2020-03-01')
GROUP BY region_name, Location
ORDER BY total_monthly_access DESC; 

/*
CREATE TABLE #temp1_table(
	monthly_access NUMERIC,
	region_name VARCHAR(100),
	Location VARCHAR(100)
	)
INSERT INTO #temp1_table
SELECT SUM(monthly_access) total_monthly_access, region_name, Location
FROM redacted lvl4
INNER JOIN redacted lvl3 ON lvl4.store_area_id = lvl3.store_area_id
INNER JOIN redacted lvl2 ON lvl3.store_region_id = lvl2.store_region_id
INNER JOIN redacted lvl1 ON lvl2.store_district_id = lvl1.store_district_id
INNER JOIN tbl_cs_tmo_daily_statement lvl0 ON lvl1.[SAP #]= lvl0.store_code
WHERE lvl3.region_name IN ('North Central') and CONVERT(datetime, lvl0.activation_date, 101) IN ('2020-03-01')
GROUP BY region_name, Location
ORDER BY total_monthly_access DESC; 
*/

--From the temporary table, find the max monthly dollar and return the store code.
SELECT [SAP #] 
FROM #temp1_table t
JOIN redacted dim ON dim.Location = t.Location 
WHERE total_monthly_access =  (SELECT  MAX(total_monthly_access) 
									From #temp1_table)

-- UPDATE ---
--The store with code (3USD) has incorrect data, create an update statement to update it total in the temporary table

BEGIN TRAN
UPDATE #temp1_table
SET total_monthly_access = 30 
WHERE Location = 'Erie'

ROLLBACK


UPDATE lvl0
SET [Old Location] = 'blahb blahb'
FROM redacted lvl4
INNER JOIN redacted lvl3 ON lvl4.store_area_id = lvl3.store_area_id
INNER JOIN redacted lvl2 ON lvl3.store_region_id = lvl2.store_region_id
INNER JOIN redacted lvl1 ON lvl2.store_district_id = lvl1.store_district_id
INNER JOIN tbl_cs_tmo_daily_statement lvl0 ON lvl1.[SAP #]= lvl0.store_code
WHERE lvl3.region_name IN ('North Central') and CONVERT(datetime, lvl0.activation_date, 101) IN ('2020-03-01')





SELECT *
FROM redacted
WHERE [SAP #] = '3USD'

--- DELETE ---
--Find all store with Zero Monthl Access and Delete the data from the temporary table.
DELETE FROM #temp1_table WHERE total_monthly_access = 0;



--Advanced SQL--
/* write a Dynamic SQL that grab a region name from store region table
& pass it into a variable 
then pass it into to a Dynamic SQL for a SELECT statement to return all the district within it.
loop the whole process for a handful of region
save the statement into a temporary table */

DECLARE @sql nvarchar(255), 
		@REGIONNAME nvarchar(255),
		@count NUMERIC(18)

--CREATE TABLE #TEMPTABLE  
--		(  region_name   varchar(255), 
--		   district_name varchar(255))

DECLARE @region_name VARCHAR(100),
@fix_name VARCHAR(100) = 'North Central'

SET @sql = 'INSERT INTO #TEMPTABLE (region_name)'

SELECT @sql


SET @sql = @sql + ' SELECT region_name FROM redacted WHERE region_name = '''+ @fix_name+ ''' '
SELECT @sql

EXEC (@sql)

SELECT @count =1

WHILE (@count <= 5) 
BEGIN 
	SELECT @region_name = region_name 
	FROM #TEMPTABLE 
	WHERE district_name IS NULL


	
UPDATE t
			SET district_name = sd.district_name
			FROM #TEMPTABLE t
			JOIN redacted sr on sr.region_name = t.region_name
			JOIN redacted sd on sd.store_region_id = sr.store_region_id


EXEC (@sql)
SET @count = @count +1

END


Cursor

/*
INSERT INTO @TEMPTABLE values(' ', ' ')

DECLARE @TABLECURSOR cursor,
		

WHILE

EXEC (@STAT)
*/

/*
DECLARE @SQL nvarchar(1000)
 
declare @Pid varchar(50)
set @pid = '680'
 
 
SET @SQL = 'SELECT ProductID,Name,ProductNumber FROM SalesLT.Product where ProductID = '+ @Pid
 
EXEC (@SQL)
/*