/*
File:	utils/sqlserver/vw_semester.sql

Desc:	Single record view for providing access to common semester/term codes.

Note:	Some re-working may need to occur depending on when a term is no longer
		considered current.
		
See:	[ utils/oracle/vw_semester.sql ] - Oracle counterpart utility;
		[ utils/sqlserver/vw_sem_alternate.sql ] - different semester window defition;
		
Enhancements:
		* Convert this to call against the Oracle view (so logic is in one place).
				
Usage:	select current_term from uis_utils.vw_semester

Schema:	current_term	: Current term ID, e.g. 420151
		previous_term	: Previous term relative to the current term
		next_term		: Next term relative " "
		next_fall_term	: Next Fall term " ", if current_term is Fall, it is a year ahead;
		cur_term_name	: Readable name of the current term, e.g. "Spring 2015", for term = 420151;
		prev_term_name	: " " previous term relative to the current term
		next_term_name	: " " next term " "
		
		academic_year	: Academic year, e.g. 1415

Author: Vern Huber
*/
use MSDB

-- Create the view if it does not exist...
if OBJECT_ID( N'dbo.vw_semester', N'U') IS NULL
begin
	EXEC sp_ExecuteSQL  N'CREATE view [dbo].[vw_semester]  as  select 1 as x' 
	print 'View stub created for: [dbo.vw_semester]'
end
-- drop view dbo.vw_semester

-- New method of accessing [vw_semester] from common location in ORAPROD.
ALTER view [dbo].[vw_semester] as 
select * from openquery( oraprod,  'select * from uis_utils.vw_semester') ;


/* CUR_PAST_SEMESTERS 

Issue with accessing in large joined db object operations - you might see:

   OLE DB provider "OraOLEDB.Oracle" for linked server "oraprod" returned message "ORA-01403: no data found".
   Msg 7346, Level 16, State 2, Line 1
   Cannot get the data of the row from the OLE DB provider "OraOLEDB.Oracle" for linked server "oraprod".
   
...and some will work.  

!!!! So view was converted to a table that is refreshed by:

	msdb.dbo.REFRESH_CUR_PAST_SEMESTERS() procedure INVOKED BY A JOB of the same name on a daily basis.
	...SSMS: SQL Server Agent --> Jobs;
	
!!!!
*/
/*  ...no longer a view...

-- drop view dbo.cur_past_semesters
if OBJECT_ID( N'dbo.[cur_past_semesters]', N'U') IS NULL
begin
	EXEC sp_ExecuteSQL  N'CREATE view [dbo].[cur_past_semesters]  as  select 1 as x' 
	print 'View stub created for: [dbo.vw_semester]'
end

-- create view [dbo].[cur_past_semesters] as 
-- select * from openquery( oraprod,  'select * from uis_cdm.cur_past_semesters') ;

-- New method of accessing [cur_past_semesters] from common location in ORAPROD.
ALTER view [dbo].[cur_past_semesters] as 
select
   CURRENT_TERM,PREVIOUS_TERM,NEXT_TERM,NEXT_FALL_TERM,EFF_START_DT,EFF_END_DT,TERM_START_DT,TERM_END_DT
   ,CUR_TERM_NAME,PREV_TERM_NAME,NEXT_TERM_NAME,NEXT_FALL_TERM_NAME,TERM_CD_CAMPUS_CD,TERM_CD_CAMPUS_NAME            
   ,CUR_SEM_CODE,PREV_SEM_CODE,NEXT_SEM_CODE
   ,ACADEMIC_YEAR,TERM_HOUSING_START_DT,TERM_HOUSING_END_DT,TERM_TYPE_CD,TERM_EDW_EFF_DT,TERM_POST_DT,CENSUS_DT
from openquery( oraprod,  'select
   CURRENT_TERM,PREVIOUS_TERM,NEXT_TERM,NEXT_FALL_TERM,EFF_START_DT,EFF_END_DT,TERM_START_DT,TERM_END_DT
   ,CUR_TERM_NAME,PREV_TERM_NAME,NEXT_TERM_NAME,NEXT_FALL_TERM_NAME,TERM_CD_CAMPUS_CD,TERM_CD_CAMPUS_NAME            
   ,CUR_SEM_CODE,PREV_SEM_CODE,NEXT_SEM_CODE
   ,ACADEMIC_YEAR,TERM_HOUSING_START_DT,TERM_HOUSING_END_DT,TERM_TYPE_CD,TERM_EDW_EFF_DT,TERM_POST_DT,CENSUS_DT 
from uis_cdm.cur_past_semesters') ;
*/

-- drop view  [dbo].[cur_past_semesters];
select
   CURRENT_TERM,PREVIOUS_TERM,NEXT_TERM,NEXT_FALL_TERM,EFF_START_DT,EFF_END_DT,TERM_START_DT,TERM_END_DT
   ,CUR_TERM_NAME,PREV_TERM_NAME,NEXT_TERM_NAME,NEXT_FALL_TERM_NAME,TERM_CD_CAMPUS_CD,TERM_CD_CAMPUS_NAME            
   ,CUR_SEM_CODE,PREV_SEM_CODE,NEXT_SEM_CODE
   ,ACADEMIC_YR as academic_year,TERM_HOUSING_START_DT,TERM_HOUSING_END_DT,TERM_TYPE_CD,TERM_EDW_EFF_DT,TERM_POST_DT,CENSUS_DT
into  [dbo].[cur_past_semesters]
from openquery( oraprod,  'select
   CURRENT_TERM,PREVIOUS_TERM,NEXT_TERM,NEXT_FALL_TERM,EFF_START_DT,EFF_END_DT,TERM_START_DT,TERM_END_DT
   ,CUR_TERM_NAME,PREV_TERM_NAME,NEXT_TERM_NAME,NEXT_FALL_TERM_NAME,TERM_CD_CAMPUS_CD,TERM_CD_CAMPUS_NAME            
   ,CUR_SEM_CODE,PREV_SEM_CODE,NEXT_SEM_CODE
   ,ACADEMIC_YR,TERM_HOUSING_START_DT,TERM_HOUSING_END_DT,TERM_TYPE_CD,TERM_EDW_EFF_DT,TERM_POST_DT,CENSUS_DT 
from uis_cdm.cur_past_semesters') ;

-- Reflect this JOB as needing to be ran daily
insert into [jobsLog].[dbo].[Jobs] ([appid],[jobname],[run_interval],[is_active]) values( NULL, 'Refresh_Cur_Past_Semesters', 1, 'Y');

-- 133
alter procedure dbo.refresh_cur_past_semesters
as
begin
   begin TRY
    set nocount on;
    
    MERGE  [dbo].[cur_past_semesters]  AS  T
    USING (
	select
      CURRENT_TERM,PREVIOUS_TERM,NEXT_TERM,NEXT_FALL_TERM,EFF_START_DT,EFF_END_DT,TERM_START_DT,TERM_END_DT
      ,CUR_TERM_NAME,PREV_TERM_NAME,NEXT_TERM_NAME,NEXT_FALL_TERM_NAME,TERM_CD_CAMPUS_CD,TERM_CD_CAMPUS_NAME            
      ,CUR_SEM_CODE,PREV_SEM_CODE,NEXT_SEM_CODE
      ,ACADEMIC_YR as ACADEMIC_YEAR,TERM_HOUSING_START_DT,TERM_HOUSING_END_DT,TERM_TYPE_CD,TERM_EDW_EFF_DT,TERM_POST_DT,CENSUS_DT
   --
   from openquery( oraprod,  '
      select
         CURRENT_TERM,PREVIOUS_TERM,NEXT_TERM,NEXT_FALL_TERM,EFF_START_DT,EFF_END_DT,TERM_START_DT,TERM_END_DT
         ,CUR_TERM_NAME,PREV_TERM_NAME,NEXT_TERM_NAME,NEXT_FALL_TERM_NAME,TERM_CD_CAMPUS_CD,TERM_CD_CAMPUS_NAME            
         ,CUR_SEM_CODE,PREV_SEM_CODE,NEXT_SEM_CODE
         ,ACADEMIC_YR,TERM_HOUSING_START_DT,TERM_HOUSING_END_DT,TERM_TYPE_CD,TERM_EDW_EFF_DT,TERM_POST_DT,CENSUS_DT 
      from uis_cdm.cur_past_semesters')
	) AS S (
      CURRENT_TERM,PREVIOUS_TERM,NEXT_TERM,NEXT_FALL_TERM,EFF_START_DT,EFF_END_DT,TERM_START_DT,TERM_END_DT
      ,CUR_TERM_NAME,PREV_TERM_NAME,NEXT_TERM_NAME,NEXT_FALL_TERM_NAME,TERM_CD_CAMPUS_CD,TERM_CD_CAMPUS_NAME            
      ,CUR_SEM_CODE,PREV_SEM_CODE,NEXT_SEM_CODE
      ,ACADEMIC_YEAR,TERM_HOUSING_START_DT,TERM_HOUSING_END_DT,TERM_TYPE_CD,TERM_EDW_EFF_DT,TERM_POST_DT,CENSUS_DT
	)
    ON (T.current_term = s.current_term)
    WHEN MATCHED THEN 
        UPDATE SET PREVIOUS_TERM = s.PREVIOUS_TERM,  NEXT_TERM = s.NEXT_TERM,  NEXT_FALL_TERM = s.NEXT_FALL_TERM
		, EFF_START_DT = s.EFF_START_DT,  EFF_END_DT = s.EFF_END_DT,  TERM_START_DT = s.TERM_START_DT, TERM_END_DT = s.TERM_END_DT
        , CUR_TERM_NAME = s.CUR_TERM_NAME,  PREV_TERM_NAME = s.PREV_TERM_NAME,  NEXT_TERM_NAME = s.NEXT_TERM_NAME
		, NEXT_FALL_TERM_NAME = s.NEXT_FALL_TERM_NAME,  TERM_CD_CAMPUS_CD = s.TERM_CD_CAMPUS_CD,  TERM_CD_CAMPUS_NAME = s.TERM_CD_CAMPUS_NAME       
        , CUR_SEM_CODE = s.CUR_SEM_CODE,  PREV_SEM_CODE = s.PREV_SEM_CODE, NEXT_SEM_CODE = s.NEXT_SEM_CODE
        , ACADEMIC_YEAR = s.ACADEMIC_YEAR,  TERM_HOUSING_START_DT = s.TERM_HOUSING_START_DT, TERM_HOUSING_END_DT = s.TERM_HOUSING_END_DT
		, TERM_TYPE_CD = s.TERM_TYPE_CD,  TERM_EDW_EFF_DT = s.TERM_EDW_EFF_DT,  TERM_POST_DT = s.TERM_POST_DT, CENSUS_DT = s.CENSUS_DT
   --
   WHEN NOT MATCHED THEN
      INSERT (
	     CURRENT_TERM,PREVIOUS_TERM,NEXT_TERM,NEXT_FALL_TERM,EFF_START_DT,EFF_END_DT,TERM_START_DT,TERM_END_DT
         ,CUR_TERM_NAME,PREV_TERM_NAME,NEXT_TERM_NAME,NEXT_FALL_TERM_NAME,TERM_CD_CAMPUS_CD,TERM_CD_CAMPUS_NAME            
         ,CUR_SEM_CODE,PREV_SEM_CODE,NEXT_SEM_CODE
         ,ACADEMIC_YEAR,TERM_HOUSING_START_DT,TERM_HOUSING_END_DT,TERM_TYPE_CD,TERM_EDW_EFF_DT,TERM_POST_DT,CENSUS_DT
	  ) VALUES (
	    s.CURRENT_TERM, s.PREVIOUS_TERM, s.NEXT_TERM, s.NEXT_FALL_TERM, s.EFF_START_DT,  s.EFF_END_DT, s.TERM_START_DT, s.TERM_END_DT
        , s.CUR_TERM_NAME, s.PREV_TERM_NAME, s.NEXT_TERM_NAME, s.NEXT_FALL_TERM_NAME, s.TERM_CD_CAMPUS_CD, s.TERM_CD_CAMPUS_NAME       
        , s.CUR_SEM_CODE, s.PREV_SEM_CODE, s.NEXT_SEM_CODE, s.ACADEMIC_YEAR, s.TERM_HOUSING_START_DT, s.TERM_HOUSING_END_DT
		, s.TERM_TYPE_CD, s.TERM_EDW_EFF_DT, s.TERM_POST_DT, s.CENSUS_DT
	 );
	
      -- Report on successful run...
      insert into [jobsLog].[dbo].[log] (jobName, [body], retcode, serverName ) 
	  values( 'Refresh_Cur_Past_Semesters', 'SUCCESS', 1, @@servername );   
   end TRY
   begin CATCH
   -- Report on successful run...
      insert into [jobsLog].[dbo].[log] (jobname, [body], retcode, serverName ) 
	  values( 'Refresh_Cur_Past_Semesters', 'FAILURE: error = ' + ERROR_NUMBER(), -1, @@serverName ); 
   end CATCH   
end;
-- OUTPUT deleted.*, $action, inserted.* INTO #MyTempTable;

exec dbo.refresh_cur_past_semesters

