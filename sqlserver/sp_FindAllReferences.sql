/*
File:	utils/sqlserver/sp_FindAllReferences.sql

Desc:	Utility that finds references across DBs on the server.
		This requires iterating across DBs and searching individually.
		...Oracle handles this in a common dictionary (across schemas).
		
		DDL support tables [UIS_ALL_DATABASES] and [UIS_ALL_DEPENDENCIES] are
		recreated as needed (to refresh the data set).		

Note: 	Not all DBs have SYSOBJECTS, but the typical ones we are interested do.
		...[xds] does not - so skip it
		...but if a DB is needing to be checked - look forthis objects existence
		and bring it in accordingly (with a false table with NULL [xtype])

Usage:
	[dbo].[sp_refreshReferences] ;  -- refresh the dependency references.
	
	[dbo].[sp_findAllreferences] 'ADdump' ;  -- find references to [ADdump]
	
	[dbo].[sp_findAllreferences]  @find_obj = 'ADdump', @refresh_flag = 'Y' ;  -- ...refresh first

References:
Link Referenced:
http://stackoverflow.com/questions/3681291/find-all-references-to-an-object-in-an-sql-server-database
...within DB

https://www.mssqltips.com/sqlservertip/2999/different-ways-to-find-sql-server-object-dependencies/
...go across DB

Created:	Vern Huber 6/5/2023
*/
USE [master];

/* sp_refreshReferences - rebuild and refresh DB and Dependencies list

*/
alter  procedure [dbo].[sp_refreshReferences]
as
BEGIN
   set NOCOUNT ON;
   
DECLARE 
   @database_id			int
   , @database_name		sysname
   , @sql				varchar(max);
   
   -- Refresh referenced data or create it in the first place.
   drop table if exists  dbo.UIS_ALL_DATABASES ;
   --
   create table  dbo.UIS_ALL_DATABASES( database_id int,  database_name sysname );
	  
   -- set of non-system DBs...
   insert into  dbo.UIS_ALL_DATABASES(database_id, database_name)
   select database_id, name  from sys.databases  where database_id > 4 and name != 'xds'  and state = 0;  -- 0 is ONLINE	
   
   drop table if exists dbo.UIS_ALL_DEPENDENCIES ;
   -- 
   create table dbo.UIS_ALL_DEPENDENCIES(
      referencing_db 			varchar(max)
	  , referencing_schema 		varchar(max)
	  , referencing_obj_name 	varchar(max)
	  , referencing_obj_type	char( 5 )
	  , referenced_server 		varchar(max)
	  , referenced_db 			varchar(max)
	  , referenced_schema 		varchar(max)
	  , referenced_obj_name 	varchar(max)
   );
   --
   while ( select count(*) from  dbo.UIS_ALL_DATABASES ) > 0 begin
      select TOP 1 @database_id = database_id,  @database_name = database_name  from  dbo.UIS_ALL_DATABASES;
	  
      set @sql = 'INSERT into dbo.UIS_ALL_DEPENDENCIES( '
	  + '  referencing_db, referencing_schema, referencing_obj_name, referencing_obj_type, referenced_server'
	  + ', referenced_db, referenced_schema, referenced_obj_name '
	  + ') '
	  + 'SELECT  DB_NAME('  + convert( varchar, @database_id ) + ')  referencing_db'
	  + ', OBJECT_SCHEMA_NAME( d.referencing_id,'  + convert( varchar, @database_id ) + ')  referencing_schema'
	  + ', OBJECT_NAME( d.referencing_id,'  + convert( varchar, @database_id ) + ')  referencing_obj_name'
   	  + ', s.xtype as referencing_obj_type '
	  + ', d.referenced_server_name  referenced_server'
	  + ', ISNULL( d.referenced_database_name, DB_NAME('  + convert( varchar,@database_id )  + '))  referenced_db '
	  + ', d.referenced_schema_name  referenced_schema, d.referenced_entity_name  referenced_obj_name '
	  + 'FROM '   + quotename( @database_name )  + '.sys.sql_expression_dependencies  D  '
	  + 'LEFT JOIN '  + quotename( @database_name )  + '.sys.SYSOBJECTS  S  on d.referencing_id = s.id ';

      exec( @sql );

      delete from dbo.UIS_ALL_DATABASES  where database_id = @database_id; 
	
   end;	-- while iterating on  dbo.UIS_ALL_DATABASES
	   
   -- Add DBs set back as a reference...
   insert into dbo.UIS_ALL_DATABASES(database_id, database_name)
   select database_id, name  from sys.databases  where database_id > 4 and name != 'xds'  and state = 0;  -- 0 is ONLINE	
   
   set NOCOUNT OFF;

END;	-- sp_refreshReferences


alter procedure  [dbo].[sp_findAllreferences]
   @find_obj 			nvarchar(128)
   , @refresh_flag		nvarchar( 1 ) = 'N'
as
BEGIN
   set NOCOUNT ON;
   
DECLARE 
   @database_id		int
   , @database_name	sysname
   , @sql			varchar(max);
   
   
   -- Refresh referenced data or create it in the first place.
   if (  @refresh_flag = 'Y'  or  OBJECT_ID(N'dbo.UIS_ALL_DATABASES', N'U') IS NULL )
   begin 
       exec dbo.sp_refreshReferences;
   end;	
	  
   select *  from dbo.UIS_ALL_DEPENDENCIES  where referenced_obj_name = @find_obj ;

END;	-- sp_findAllreferences



-- http://stackoverflow.com/questions/3681291/find-all-references-to-an-object-in-an-sql-server-database
-- ...within DB
--
-- Eg:  exec dbo.SP_FindAllReferences 'edw_facsec'
--
CREATE PROCEDURE [dbo].[SP_FindAllReferences]
@targetText nvarchar(128)
AS
BEGIN
    SET NOCOUNT ON;

    declare @origdb nvarchar(128)
    select @origdb = db_name()

    declare @sql nvarchar(1000)

    set @sql = 'USE [' + @origdb +'];' 
    set @sql += 'select object_name(m.object_id), m.* '
    set @sql += 'from sys.sql_modules m  where m.definition like N' + CHAR(39) + '%' + @targetText + '%' + CHAR(39)

    exec (@sql)

    SET NOCOUNT OFF;
END
