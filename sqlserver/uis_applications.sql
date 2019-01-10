/*
File:	utils/sqlserver/pop_applications.sql

Desc:	Script for populating applications [msdb.dbo.APPLICATION].

Note:	The [appID] MUST BE THE SAME across all environments (dev/test/prod), as well
		as all DBs used (Oracle, SQL Server, MySQL).
		
		As of Sept 16, 2015, SQL Server instances for dev/test/prod refer to their Oracle
		counterparts - as a view.  This keeps entries in sync for Oracle and SQL Server.
		
		MySQL can still have an issue.
		
		---
		appID = 10 is for holding things common across all applications.
		
See:	README_utils.docx in this dir for related info.

		[oracle/pop_applications.sql] - for corresponding Oracle code.

WARNING: Never use the [acronym] as the key - that's what the [appID] is for.

Author: Vern Huber
*/

use msdb

alter view dbo.applications as select appID, app_ACRONYM, app_BASE_URL, app_DESC, app_TITLE, DEBUGGING, DEBUG_LEVEL
from openquery( ORAPROD, 
   'select  appID, app_ACRONYM, app_BASE_URL, app_DESC, app_TITLE, DEBUGGING, DEBUG_LEVEL  from team.application where is_active = ''Y'' and campusID = 4 ' );

grant select on msdb.dbo.applications to public;
commit;
