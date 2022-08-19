GO
/****** Object:  StoredProcedure [dbo].[[redacted]]    Script Date: 6/16/2022 4:25:24 PM 
Author: Kwaku Baryeh 
Description: 
Date: 6/16/2022
******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[redacted] 
AS

BEGIN
	CREATE TABLE #import_data (
		str_data VARCHAR(1000))

	CREATE TABLE #import_data_cleaned(
		files_name			VARCHAR(100),
		creation_datetime DATETIME )

	CREATE TABLE #error_message(
	error_type VARCHAR(50),
	error_value NUMERIC(18)	)

	DECLARE @lv_body NVARCHAR(MAX),
				@lv_tablehead VARCHAR(1000),
				@lv_tabletail VARCHAR(1000),
				@html_output VARCHAR(MAX),
				@lv_subject_msg VARCHAR(200),
				@lv_body_msg VARCHAR(MAX) 

	SET @lv_tabletail = '</table></body></html>' ;

	SET @lv_tablehead = '<html><head>' + '<style>'
				+ 'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 13px arial} '
				+ '</style>' + '</head>' + '<body>' 
				+'<h1>Operational Alerts</h1>'
				+ 'Report generated on : '			+ CONVERT(VARCHAR(50), GETDATE(), 101) 
				+ ' <br>' 
	SET @lv_subject_msg = 'Operational Alerts - '+CONVERT(VARCHAR(50), GETDATE(), 101)

	INSERT INTO #import_data 
		(str_data)
	EXEC xp_cmdshell 'dir D:\import\*.csv'

	DELETE FROM #import_data 
	WHERE str_data IS NULL
	OR		str_data LIKE '% Volume %'
	OR		str_data LIKE '% Directory %'
	OR		str_data LIKE '%bytes%'
	OR		str_data LIKE '%<DIR>%'


	INSERT INTO #import_data_cleaned( 
		files_name, 
		creation_datetime)
	SELECT	
			REVERSE( LEFT(REVERSE(str_data),CHARINDEX(' ',REVERSE(str_data))-1 ) )  files_name,
			SUBSTRING(str_data, 2, PATINDEX('%[AP]M%', str_data)) as creation_datetime
	FROM #import_data r
	WHERE r.str_data <> 'File Not Found'

	
	INSERT INTO #error_message
	SELECT 'unprocessed files',COUNT(creation_datetime) unprocessed_files
	FROM #import_data_cleaned
	WHERE DATEDIFF(hh, creation_datetime, GETDATE()) > 1
	HAVING COUNT(creation_datetime) > 0


	INSERT INTO #error_message
	SELECT 'Files that in Error', COUNT(*)  num_status_errs
	FROM tbl_cs_tmo_files_upload
	WHERE file_status = 'ERROR'

	INSERT INTO #error_message
	SELECT 'Files that in New', Count(*) num_status_new
	FROM tbl_cs_tmo_files_upload
	WHERE file_status = 'NEW' and DATEDIFF(hh, insert_datetime, GETDATE()) > 1
	

	IF EXISTS 
	(
	SELECT * 
	FROM #error_message 
	WHERE error_value > 0
	)
	BEGIN
		DECLARE @sql VARCHAR(MAX) ='SELECT error_type [Error Type],error_value[# of Files] FROM #error_message WHERE error_value > 0'


		EXEC dbp_cs_tmo_query_to_html_table 
					@sql, --- query
					'', --- order by 
					@html_output OUTPUT

		SET @lv_body_msg = @lv_tablehead + @html_output + @lv_tabletail


		EXECUTE msdb.dbo.sp_send_dbmail    
				@profile_name		= 'CSAnalytics',    
				@recipients			= 'redacted',    
				@copy_recipients	= 'redacted',      
				@subject				= @lv_subject_msg,    
				@body					= @lv_body_msg ,    
				@body_format		= 'HTML',
				@from_address		= 'redacted'
	END
	DROP TABLE #error_message
	DROP TABLE #import_data_cleaned
	DROP TABLE #import_data

END
GRANT EXECUTE ON [redacted] TO csuser1

