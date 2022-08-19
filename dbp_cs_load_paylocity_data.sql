    
        
CREATE PROCEDURE [dbo].[redacted] ( @debug VARCHAR(1) = 'N' )        
AS        
        
        
BEGIN        
 DECLARE @lv_body NVARCHAR(MAX),        
  @lv_tablehead VARCHAR(1000),        
  @lv_tabletail VARCHAR(1000)        
        
 DECLARE @lv_full_file_path VARCHAR(200),        
  @ln_file_upload_id NUMERIC(18),        
  @lv_format_file VARCHAR(256),        
  @lv_file_code VARCHAR(20),        
  @lv_sql VARCHAR(MAX),        
  @lv_data_error_yn VARCHAR(1),        
  @ldt_today DATETIME,        
  @lv_user VARCHAR(100),        
  @lv_process VARCHAR(100),        
  @lv_error_message VARCHAR(100),        
  @lv_file_status VARCHAR(50)        
        
 DECLARE @start_date DATE,        
  @end_date DATE,        
  @month_int INT,        
  @max_worked_date DATETIME,        
  @file_count NUMERIC(5),        
  @lv_body_msg VARCHAR(MAX),        
  @lv_subject_msg VARCHAR(100)        
        
 SET @ldt_today = GETDATE()        
 SET @lv_user = HOST_NAME()        
 SET @lv_process = 'PYLCITY_BULK'        
 SET @lv_data_error_yn = 'N'        
 SET @lv_tabletail = '</table> <b>Paylocity Active Employee Without Clock Data on Payroll. Please Confirm </b></body></html>';        
 SET @lv_tablehead = '<html><head>' + '<style>' + 'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} ' + '</style>' + '</head>' + '<body>' + 'Report generated on : ' + CONVERT
  
    
      
(VARCHAR(50), GETDATE(), 101) + ' <br> <table cellpadding=0 cellspacing=0 border=0>' + '<tr> <td bgcolor=#ea0a8e><b>Last Worked Date</b></td>' + '<td bgcolor=#ea0a8e><b>Employee ID</b></td>' + '<td bgcolor=#ea0a8e><b>First Name</b></td>' +         
  '<td bgcolor=#ea0a8e><b>Last Name</b></td></tr>';        
        
 CREATE TABLE #t_paylocity_time_detail (        
  employee_id VARCHAR(255) NULL,        
  old_paycom_id VARCHAR(255) NULL,        
  nt_id VARCHAR(255) NULL,        
  first_name VARCHAR(255) NULL,        
  last_name VARCHAR(255) NULL,        
  job_title VARCHAR(255) NULL,        
  home_dept_code VARCHAR(255) NULL,        
  clocked_dept_code VARCHAR(255) NULL,        
  clocked_dept_name VARCHAR(255) NULL,        
  job_title_name VARCHAR(255) NULL,        
  district_name VARCHAR(255) NULL,        
  work_date DATETIME NULL,        
  pay_type_description VARCHAR(255) NULL,        
  punch_in_time DATETIME NULL,        
  punch_out_time DATETIME NULL,        
  punch_in_time_rounded DATETIME NULL,        
  punch_out_time_rounded DATETIME NULL,        
  punch_in_type VARCHAR(255) NULL,        
  punch_out_type VARCHAR(255) NULL,        
  regular_duration_hrs FLOAT NULL,        
  ot_1_duration_hrs FLOAT NULL,        
  ot_2_duration_hrs FLOAT NULL,        
  unpaid_duration_hrs FLOAT NULL,        
  supervisor_approval VARCHAR(255) NULL,        
  employee_approval VARCHAR(255) NULL,        
  supervisor_approval_by VARCHAR(255) NULL,        
  tenure_in_months FLOAT NULL,        
  termination_date DATETIME NULL,    
  base_rate NUMERIC(18,4) NULL    
  )        
        
 CREATE TABLE #t_paylocity_userlist (        
  employee_id VARCHAR(255) NULL,        
  current_employee_status VARCHAR(255) NULL,        
  hire_date DATETIME NULL,        
  termination_date DATETIME NULL,        
  department_code VARCHAR(255) NULL,        
  department_name VARCHAR(255) NULL,        
  job_title_code VARCHAR(255) NULL,        
  job_title_name VARCHAR(255) NULL,        
  email_address VARCHAR(255) NULL,        
  nt_id VARCHAR(255) NULL,        
  old_paycom_id VARCHAR(255) NULL,        
  first_name VARCHAR(255) NULL,        
  last_name VARCHAR(255) NULL,        
  created_on DATETIME NULL,        
  rehire_date DATETIME NULL,        
  ssn VARCHAR(4) NULL,        
  user_district VARCHAR(150) NULL,        
  user_region VARCHAR(150) NULL,        
  user_area VARCHAR(150) NULL  
  )        
        
 CREATE TABLE #file_to_load (        
  file_upload_id NUMERIC(18),        
  file_code VARCHAR(100),        
  format_file VARCHAR(200),     
  files_name VARCHAR(200),        
  file_path VARCHAR(200),        
  full_file_path VARCHAR(200),        
  error_yn VARCHAR(1)        
  )        
        
    
    
    
    
 INSERT INTO #file_to_load (        
  file_upload_id,        
  file_code,        
  format_file,        
  files_name,        
  file_path,        
  full_file_path,        
  error_yn        
  )        
 SELECT tfu.file_upload_id,        
  tfu.file_code,        
  trt.format_file,        
  tfu.files_name,        
  tfu.file_path,        
  tfu.file_path + tfu.files_name, ---full_file_path            
  'N' --error_yn            
 FROM dbo.tbl_cs_tmo_files_upload tfu        
 INNER JOIN dbo.tbl_cs_tmo_report_type trt ON trt.report_code = tfu.file_code        
 WHERE tfu.file_code IN (        
   'PC_USER_LIST',     
   'PC_TIME_RPT'        
  )         
  AND tfu.file_status = 'NEW'        
        
        
 ------------------------------------------------------------------------------              
 ------------------ load paylocity user list report --------------------              
 ------------------------------------------------------------------------------              
 DECLARE paylocity_cursor CURSOR        
 FOR        
 SELECT file_upload_id,        
  full_file_path,        
  file_code,        
  format_file        
 FROM #file_to_load ftl        
        
 OPEN paylocity_cursor        
        
 FETCH NEXT        
 FROM paylocity_cursor        
 INTO @ln_file_upload_id,        
  @lv_full_file_path,        
  @lv_file_code,        
  @lv_format_file        
        
 WHILE @@FETCH_STATUS = 0        
 BEGIN        
  IF @lv_file_code = 'PC_USER_LIST'        
  BEGIN        
   BEGIN TRY        
    SET @lv_sql =         
     'INSERT INTO #t_paylocity_userlist            
     ( employee_id     ,            
      current_employee_status ,            
      hire_date     ,            
      termination_date   ,            
      job_title_code    ,            
      job_title_name    ,          
      department_code   ,            
      department_name   ,         
      email_address    ,            
      nt_id       ,            
      old_paycom_id    ,            
      first_name     ,            
      last_name     ,            
      rehire_date     ,            
      ssn       ,        
      user_district,        
      user_region,        
      user_area )'        
    SET @lv_sql = @lv_sql +         
     N'SELECT TRIM(REPLACE(employee_id,''"'','''')) employee_id,              
         TRIM(REPLACE(curnnt_employee_status,''"'',''''))curnnt_employee_status,              
         curnnt_hire_date,              
         currnt_termination_date,              
         TRIM(REPLACE(curnnt_job_title_code,''"'',''''))curnnt_job_title_code,              
         TRIM(REPLACE(curnnt_job_title_name,''"'',''''))curnnt_job_title_name,              
         TRIM(REPLACE(curnnt_department_code,''"'',''''))curnnt_department_code,              
         TRIM(REPLACE(curnnt_department_name,''"'',''''))curnnt_department_name,                      
         NULLIF(TRIM(REPLACE(email,''"'','''')),'''')email,              
         NULLIF(TRIM(REPLACE(nt_id,''"'','''')),'''')nt_id,              
         TRIM(REPLACE(paycom_id,''"'',''''))paycom_id,                         
         TRIM(REPLACE(first_name,''"'',''''))first_name,              
         TRIM(REPLACE(last_name,''"'',''''))last_name,              
         TRIM(REPLACE(rehire_date,''"'','''')) rehire_date,            
         RIGHT(REPLACE(ssn,''"'',''''),4)    ssn,        
         TRIM(REPLACE(district,''"'',''''))user_district,        
         TRIM(REPLACE(region,''"'',''''))user_region,         
         TRIM(REPLACE(area,''"'',''''))user_area        
      FROM OPENROWSET(BULK '''         
        + @lv_full_file_path + ''',            
      FORMATFILE = ''' + @lv_format_file + ''',            
      FIRSTROW = 2) AS paylc_user '        
        
    EXEC (@lv_sql)        
        
    SET @lv_data_error_yn = 'N'        
    SET @lv_file_status = 'ARCHIVE'        
      
  TRUNCATE TABLE redacted       
   END TRY        
        
   BEGIN CATCH        
    SET @lv_data_error_yn = 'Y'        
    SET @lv_error_message = ERROR_MESSAGE()        
    SET @lv_file_status = 'ERROR'        
      /*  
    CLOSE paylocity_cursor        
        
    DEALLOCATE paylocity_cursor        
        */
    --GOTO EOP;        
   END CATCH        
  END        
        
  IF @lv_file_code = 'PC_TIME_RPT'      
  BEGIN        
   BEGIN TRY        
    SET @lv_sql =         
     'INSERT INTO #t_paylocity_time_detail (            
      employee_id   ,            
      old_paycom_id  ,            
      nt_id     ,            
      first_name ,            
      last_name   ,            
      job_title   ,            
      home_dept_code ,            
      clocked_dept_code   ,            
      clocked_dept_name ,            
      job_title_name  ,            
      district_name   ,            
      work_date   ,            
      pay_type_description  ,            
      punch_in_time    ,            
      punch_out_time    ,            
      punch_in_time_rounded ,            
      punch_out_time_rounded ,            
      punch_in_type    ,            
      punch_out_type    ,            
      regular_duration_hrs  ,            
      ot_1_duration_hrs   ,            
      ot_2_duration_hrs   ,            
      unpaid_duration_hrs  ,            
      supervisor_approval  ,            
      employee_approval   ,            
      supervisor_approval_by ,            
      tenure_in_months   ,            
      termination_date  ,    
  base_rate)'        
    SET @lv_sql = @lv_sql +         
     N'SELECT                 
      TRIM(REPLACE(employee_id,''"'',''''))employee_id,                
      NULLIF(TRIM(REPLACE(paycom_id,''"'','''')),'''')paycom_id,                
      TRIM(REPLACE(nt_id,''"'','''')) nt_id,                
      TRIM(REPLACE(first_name,''"'',''''))first_name,                
      TRIM(REPLACE(last_name,''"'',''''))last_name,                
      TRIM(REPLACE(job_title,''"'',''''))job_title,                
      TRIM(REPLACE(home_dept_code,''"'',''''))home_dept_code,                
      TRIM(REPLACE(clocked_dept_code,''"'',''''))clocked_dept_code,                
      TRIM(REPLACE(clocked_dept_name,''"'',''''))clocked_dept_name,                
      TRIM(REPLACE(job_title_name,''"'',''''))job_title_name,                
      TRIM(REPLACE(district_name,''"'',''''))district_name,                
      work_date,                
      TRIM(REPLACE(pay_type_desc,''"'',''''))pay_type_desc,                
      punch_in_time,                
      punch_out_time,                
      punch_in_time_rounded,                
      punch_out_time_rounded,                
      TRIM(REPLACE(punch_in_type,''"'',''''))punch_in_type,                
      TRIM(REPLACE(punch_out_type,''"'',''''))punch_out_type,                
      regular_duration_hrs,                
      ot_1_duration_hrs,                
      ot_2_duration_hrs,                
      unpaid_duration_hrs,                
      supervisor_approval,                
      employee_approval,                
      NULL supervisor_approval_by,               
      tenure_in_months,                
      termination_date,    
  base_rate    
      FROM OPENROWSET(BULK '''         
      + @lv_full_file_path + ''',            
      FORMATFILE = ''' + @lv_format_file + ''',            
      FIRSTROW = 2) AS paylc_time_dtl '        
        
    EXEC (@lv_sql)        
        
    SET @lv_data_error_yn = 'N'        
    SET @lv_file_status = 'ARCHIVE'       
    
  SELECT @max_worked_date = MAX(work_date)        
  FROM #t_paylocity_time_detail        
        
  SET @start_date = DATEADD(mm, - 1, DATEADD(dd, + 1, EOMONTH(@max_worked_date)))        
  SET @end_date = EOMONTH(@start_date)       
    
  DELETE tdr        
  FROM dbo.[redacted] tdr        
  WHERE [Work Date] BETWEEN @start_date        
    AND @end_date        
       
   END TRY        
        
   BEGIN CATCH        
    SET @lv_data_error_yn = 'Y'        
    SET @lv_error_message = ERROR_MESSAGE()        
    SET @lv_file_status = 'ERROR'        
    /*    
    CLOSE paylocity_cursor        
        
    DEALLOCATE paylocity_cursor        
       */ 
    --GOTO EOP;        
   END CATCH        
  END        
     /*   
  --- Archive file ---            
  UPDATE tfu        
  SET file_path = dbo.dbf_cs_move_files(@ln_file_upload_id, @lv_file_status),        
   file_status = @lv_file_status,        
   update_datetime = @ldt_today,        
   update_user = @lv_user,        
   update_process = @lv_process        
  FROM dbo.tbl_cs_tmo_files_upload tfu       
  WHERE tfu.file_upload_id = @ln_file_upload_id        
        */ 
  FETCH NEXT        
  FROM paylocity_cursor        
  INTO @ln_file_upload_id,        
   @lv_full_file_path,        
   @lv_file_code,        
   @lv_format_file        
 END        
        
 CLOSE paylocity_cursor        
        
 DEALLOCATE paylocity_cursor        
        --- Reconsile Paylocity NTID vs Tmo NTID          
     
        
 TRUNCATE TABLE redacted        
       
 INSERT INTO redacted (        
  employee_id,        
  first_name,        
  last_name,        
  NTID        
  )        
 SELECT pu.employee_id,        
  pu.first_name,        
  pu.last_name,        
  ph.NTID_New        
 FROM #t_paylocity_userlist pu        
 INNER JOIN dbo.redacted ph ON ph.FName_New = pu.first_name        
  AND ph.SSN4 = pu.ssn        
  AND ph.LName_New = pu.last_name        
  AND ph.[Current] = 'Y'        
  AND ph.EmpStatus = 'Active'        
 WHERE pu.nt_id IS NULL        
  AND ph.NTID_New IS NOT NULL        
  AND pu.hire_date >= DATEADD(mm, - 3,@start_date)          
  AND ph.CRFinalized BETWEEN DATEADD(mm,-3,@start_date)           
   AND @end_date        
        
 --- update NT ID if missing ---             
 UPDATE pu        
 SET nt_id = ph.NTID_New        
 FROM #t_paylocity_userlist pu        
 INNER JOIN dbo.redacted ph ON ph.FName_New = pu.first_name        
  AND ph.SSN4 = pu.ssn        
  AND ph.LName_New = pu.last_name        
  AND ph.[Current] = 'Y'        
  AND ph.EmpStatus = 'Active'        
 WHERE pu.nt_id IS NULL        
  AND ph.NTID_New IS NOT NULL        
  AND pu.hire_date >= DATEADD(mm, - 3,@start_date)          
  AND ph.CRFinalized BETWEEN DATEADD(mm,-3,@start_date)         
   AND @end_date        
        
 --- Scenario of Employee not fully onboard, they will have payolcity record but no employee id ---           
 DELETE pd        
 FROM #t_paylocity_time_detail pd        
 WHERE NULLIF(employee_id, '') IS NULL        
        
 DELETE pu        
 FROM #t_paylocity_userlist pu        
 WHERE NULLIF(employee_id, '') IS NULL        
        
 IF @lv_data_error_yn = 'N'        
 BEGIN        
    
  INSERT INTO redacted (        
   [Employee ID],        
   [Employee Status - Current],        
   [Hire Date - Current],        
   [Termination Date - Current],        
   [Job Title - Code - Current],        
   [Job Title - Name - Current],        
   [Department - Code - Current],        
   [Department - Name - Current],        
   [E-mail],        
   [NT ID - Text],        
   [Paycom ID - Text],        
   [First Name],        
   [Last Name],        
   [rehire date],        
   insert_datetime,        
   insert_user,        
   insert_process,        
   user_district,        
   user_region,        
   user_area        
   )        
  SELECT employee_id,        
   current_employee_status,        
   hire_date,        
   termination_date,        
   job_title_code,        
   job_title_name,        
 department_code,        
   department_name,        
   email_address,        
   nt_id,        
   old_paycom_id,        
   first_name,        
   last_name,        
   rehire_date, --- rehire_date           
   @ldt_today,        
   @lv_user,        
   @lv_process,        
   user_district,        
   user_region,        
   user_area        
  FROM #t_paylocity_userlist        
        
  INSERT INTO [redacted] (        
   [Employee Id],        
   [Paycom ID],        
   [NT ID],        
   [First Name],        
   [Last Name],        
   [Job Title],        
   [Department Code],        
   [Department],        
   [Department Name],        
   [Job Title Name],        
   [District Name],        
   [Work Date],        
   [Pay Type Description],        
   [Punch In Time],        
   [Punch Out Time],        
   [Punch In Time (Rounded)],        
   [Punch Out Time (Rounded)],        
   [Punch In Type],        
   [Punch Out Type],        
   [Regular Duration (hours)],        
   [OT1 Duration (hours)],        
   [OT2 Duration (hours)],        
   [Unpaid Duration (hours)],        
   [Supervisor Approval],        
   [Employee Approval],        
   [Supervisor Approval By],        
   [Tenure (in Months)],        
   [Termination Date],       
 base_rate,    
   insert_datetime,        
   insert_user,        
   insert_process        
   )        
  SELECT employee_id,        
   old_paycom_id,        
   nt_id,        
   first_name,        
   last_name,        
   job_title,        
   home_dept_code,        
   clocked_dept_code,        
   clocked_dept_name,        
   job_title_name,        
   district_name,        
   work_date,        
   pay_type_description,        
   punch_in_time,        
   punch_out_time,        
   punch_in_time_rounded,        
   punch_out_time_rounded,        
   punch_in_type,        
   punch_out_type,        
   regular_duration_hrs,        
   ot_1_duration_hrs,        
   ot_2_duration_hrs,        
unpaid_duration_hrs,        
   supervisor_approval,        
   employee_approval,        
   supervisor_approval_by,        
   tenure_in_months,        
   termination_date,       
 base_rate,    
   @ldt_today,        
   @lv_user,        
   @lv_process        
  FROM #t_paylocity_time_detail        
 END        
        
 IF (ERROR_MESSAGE() IS NULL)        
 BEGIN        
  EXEC dbo.rn_LocationList        
 END        
        
 SET @lv_file_status = 'COMPLETED'        
END        
        
--EOP:        
        
--IF @lv_file_status = 'COMPLETED'        
--BEGIN        
-- SET @lv_subject_msg = '[Notice] - Paylocity Load Completed ' + (CONVERT(VARCHAR(100), @ldt_today, 101))        
-- SET @lv_body_msg = 'Paylocity Load Completed' + CHAR(13) + CHAR(10) + 'File Status: ' + @lv_file_status + CHAR(13) + CHAR(10) + 'Return Message: ' + ISNULL(@lv_error_message, 'No Error') + CHAR(13) + CHAR(10)        
        
-- /* if debug make sure to comment this portion */        

    
-- --- rebuild cube ---    
    
    
    
      
--END        
         
--IF EXISTS (        
--  SELECT 1        
--  FROM dbo.redacted        
--  )        
--BEGIN        
-- SET @lv_subject_msg = '[Alert] - Paylocity Employee Without NT_ID ' + (CONVERT(VARCHAR(100), @ldt_today, 101))        
-- SET @lv_body = 'Please see Paylocity Employee Without NT ID Dashboard .'        
        

--END        
/*        
IF EXISTS (        
  SELECT 1        
  FROM #file_to_load        
  )        
BEGIN        
 UPDATE tfu        
 SET file_status = @lv_file_status,        
  file_path = dbo.dbf_cs_move_files(@ln_file_upload_id, @lv_file_status),        
  error_msg = @lv_error_message,        
  update_datetime = @ldt_today,        
  update_user = @lv_user,        
  update_process = @lv_process        
 FROM #file_to_load fl        
 INNER JOIN dbo.tbl_cs_tmo_files_upload tfu ON fl.file_upload_id = tfu.file_upload_id        
 INNER JOIN dbo.tbl_cs_tmo_report_type trt ON trt.report_code = tfu.file_code        
END        
*/
--IF @debug = 'Y'        
--BEGIN        
-- SELECT COUNT(*)        
-- FROM redacted        
-- WHERE insert_datetime > @ldt_today        
        
-- SELECT COUNT(*)        
-- FROM redacted        
-- WHERE insert_datetime > @ldt_today        
        
-- SELECT *        
-- FROM #t_paylocity_time_detail        
        
-- SELECT *        
-- FROM #t_paylocity_userlist        
--END        
        
DROP TABLE #t_paylocity_time_detail        
DROP TABLE #t_paylocity_userlist        
DROP TABLE #file_to_load        
        
        
GRANT EXECUTE ON redacted TO redacted        
  --ROLLBACK 