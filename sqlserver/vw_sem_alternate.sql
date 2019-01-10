/*
File: 	utils/sqlserver/vw_sem_alternate.sql

Desc:	See prologue to [ utils/oracle/vw_sem_alternate.sql ]

See:	[ utils/oracle/vw_sem_alternate.sql ] - Oracle counterpart utility.		
		[ utils/sqlserver/vw_semester.sql ] - Commonly used current semester view.
		
Enhancments:
		* ___ May have to pull against [ dbo.REFRESH_CUR_PAST_SEMESTERS ] which is
		  a local table (vs. pulling the data over from Oracle).
		
Author:	Vern Huber
*/
 
 -- Create in SQL Server DBs as well....
 --
use MSDB;
-- 
CREATE view [dbo].[vw_sem_alternate] as 
   select * from openquery( oraprod,  'select * from uis_utils.vw_sem_alternate') ;

 -- ...now DEFINE - on a per APPLICATION basis, any view needing this window.
 -- ...this will make it easier to modify - in case of future changes
 --

use STUINS;
CREATE view [dbo].[vw_sem_STUINS] as 
   select * from openquery( oraprod,  'select * from uis_utils.vw_sem_STUINS') ;

 -- ...TRAC / RecSports
use Fusion_TRAC;
CREATE view [dbo].[vw_sem_TRAC] as 
   select * from openquery( oraprod,  'select * from uis_utils.vw_sem_TRAC') ;

