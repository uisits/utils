/*
File:	utils\sqlserver\uis_sys_param_lkp.sql

		Holds information needed by applications that tends to differ between platforms (dev/test/prod)
		- and you don't want to be hardcoding the settings.
		
		--
		msdb.dbo.Mv_App_Param_Lkp is refreshed by job: [ITS_REFRESH_mv_app_param_lkp], using schedule: [ITS_NIGHTLY_at_1am];
		...on both test and production (prod2 and prodmssql) SQL Server DBs.

See:	utils/sqlserver/pop_uis_sys_param_lkp.sql - which were used for populating entries in this table.
		*** DELETE eventually ***

Author: Vern Huber

		VH & Prashanth Edge - 11/30/2016:
		Converted to a table that's refreshed on a regular schedule (to break db link dependency).

Caveats / Things to Consider:
		
*/
USE [msdb]

-- This is the object to reference:
ALTER view [dbo].[uis_sys_param_lkp]
as
select  PARAM_ID, PARAM_CD, PARAM_NAME, PARAM_DESC, PARAM_VALUE, PARAM_TYPE  from dbo.Mv_App_param_Lkp ;

grant select on msdb.dbo.uis_sys_param_lkp to public;
commit;

-- Table to hold APP_PARAM_LKP entries...
-- drop table  [dbo].[Mv_App_param_Lkp];
use MSDB
CREATE TABLE [dbo].[Mv_App_param_Lkp] (
    [PARAM_ID] [numeric](10, 0) NOT NULL
	, [PARAM_CD] [nvarchar](100) NOT NULL
	, [PARAM_NAME] [nvarchar](100) NOT NULL
	, [PARAM_VALUE] [nvarchar](4000) NOT NULL
	, [PARAM_DESC] [nvarchar](4000) NOT NULL
	, [PARAM_TYPE] [nvarchar](100) NOT NULL
) ;

-- Rule view to base the refresh on...
-- ...for PRODUCTION systems:
use MSDB
CREATE VIEW [dbo].[R_App_Param_Lkp] 
AS
SELECT * FROM OPENQUERY( ORAPROD, 'select  PARAM_ID, PARAM_CD, PARAM_NAME, PARAM_VALUE, PARAM_DESC, PARAM_TYPE  
   from uis_utils.uis_sys_param_lkp  where uis_delete_flg = ''N'' ')
;
-- ...for TEST systems (not PRODUCTION):
use MSDB
CREATE VIEW [dbo].[R_App_Param_Lkp] 
AS
SELECT * FROM OPENQUERY( ORATEST, 'select  PARAM_ID, PARAM_CD, PARAM_NAME, PARAM_VALUE, PARAM_DESC, PARAM_TYPE  
   from uis_utils.uis_sys_param_lkp  where uis_delete_flg = ''N'' ')
;
-- Refresh procedure for APP_PARAM_LKP table (so it behaves like an Oracle Material View)...
-- 
-- ...invoke: exec dbo.refresh_app_param_lkp ;
--
use MSDB
alter PROCEDURE [dbo].[refresh_app_param_lkp]
as
   MERGE  INTO [dbo].[Mv_App_param_Lkp] AS  T  -- target
   USING (
      SELECT  PARAM_ID, PARAM_CD, PARAM_NAME, PARAM_VALUE, PARAM_DESC, PARAM_TYPE
	  FROM dbo.R_App_param_Lkp
   )
   AS S  -- source
   ON t.param_id = s.param_id and t.param_cd = s.param_cd
   WHEN MATCHED THEN
   UPDATE SET  
	  t.PARAM_NAME = s.PARAM_NAME
	  , t.PARAM_VALUE = s.PARAM_VALUE
	  , t.PARAM_DESC = s.PARAM_DESC
	  , t.PARAM_TYPE = s.PARAM_TYPE
   WHEN NOT MATCHED BY TARGET THEN
   INSERT (
      PARAM_ID, PARAM_CD, PARAM_NAME, PARAM_VALUE, PARAM_DESC, PARAM_TYPE
   )
   values (
      s.PARAM_ID, s.PARAM_CD, s.PARAM_NAME, s.PARAM_VALUE, s.PARAM_DESC, s.PARAM_TYPE
   )
;
--
grant execute on dbo.refresh_app_param_lkp to SANDAL;

-- Refresh object:  exec dbo.delete_app_param_lkp (delete case);
use MSDB;
--
alter PROCEDURE dbo.delete_app_param_lkp( @PARAM_ID varchar(10) , @PARAM_CD varchar(10))
AS
BEGIN
   DELETE  FROM dbo.Mv_App_param_Lkp  where PARAM_ID = @PARAM_ID and PARAM_CD = @PARAM_CD
END
;
grant execute on dbo.delete_app_param_lkp to SANDAL;

-- Define skeleton proc in [sandal] to call the real one in [msdb]...
--
use SANDAL
alter PROCEDURE [dbo].[refresh_app_param_lkp]
as
   -- Call the real refresh utility...
   exec msdb.dbo.refresh_app_param_lkp
;
--
use SANDAL
alter PROCEDURE [dbo].[delete_app_param_lkp]
as
   -- Call the real refresh utility...
   exec msdb.dbo.delete_app_param_lkp
;

-- !+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+!+
-- ...and on the Oracle side, see  [team/app_param_lkp.sql]
--

