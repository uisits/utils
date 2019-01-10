/*
File:	utils\sqlserver\uis_sendmail_log.sql

Desc:	Log of entries sent via uis_sendmail() that are Digitally Signed, and thus handled bypassing
		our Web Service (and bypassing SQL Server).  
		
		Note that this log is merged in with SQL Server's set in [sqlserver_sysmail].
				
See:	.\uis_sendmail.sql - that logs signed email entries here, since the Web Service
		handles the sending (bypassing SQL Server).

		.\CDM\all\sqlserver_sysmail.sql - for emails sent that were sent unsigned (via
		SLQ Server).

*/
USE [msdb]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view dbo.sysmail_log   as 
select  mailitem_id, profile_id, sent_date
   , CAST( subject as varchar(255) ) as recipients, CAST( subject as varchar(255) ) as subject
from msdb.dbo.sysmail_allitems 
;
