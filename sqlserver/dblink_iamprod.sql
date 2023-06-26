/*
File:	utils/sqlserver/dblink_iamprod.sqlserver/dblink_iamprod

Desc:	IAMPROD linked server for extracting AIM production data...
*/
USE [master]
GO

-- !!!!!! REMOVE password
-- !!!!!! IAMNEW --> IAMPROD
-- !!!!!! DROP iamnew

-- CHIIAMSQLPROD2 - replaced on 10/10/2020 with CHIENTSQLC2
EXEC master.dbo.sp_addlinkedserver @server = N'IAMPROD', @srvproduct=N'', @provider=N'SQLNCLI', @datasrc=N'CHIIAMSQLPROD2.AD.UILLINOIS.EDU'
--
-- EXEC master.dbo.sp_addlinkedserver @server = N'IAMPROD', @srvproduct=N'', @provider=N'SQLNCLI', @datasrc=N'CHIENTSQLC2.ad.uillinois.edu'

 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'IAMPROD',@useself=N'False',@locallogin=NULL,@rmtuser=N'IT_SQSPRRAVE_R',@rmtpassword='xxxxxxxx'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'rpc', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'rpc out', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'use remote collation', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'IAMPROD', @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO


