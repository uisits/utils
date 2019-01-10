/*
File:	utils\sqlserver\csv\export_object_csv.sql

Desc:	See [Caveats] in this prologue prior to invoking this script.
		
Note:	  Run order (code is in [utils/sqlserver/csv] unless specified otherwise):

		1) Create [export_object_csv] (using this file);
		
		2) gen_export_object_csv_cmds.sql : Query example to format a call to [export_object_csv]
			for each table in a db/schema.
			
			This will generate a list of entries (1 per table) like:
			
			exec pipp.dbo.export_object_csv 'RecertificationStatus', 'RecertificationStatus.csv'
			
		3) Apply the output from [Step 2];  This will generate a list of [bcp] commands (1 per table)
			that look like:
			
			bcp "SELECT '\"VendorAgencyId\"' AS VendorAgencyId,  ...for column headings
				 UNION ALL
                 SELECT '\"' + CAST(REPLACE(VendorAgencyId,'\"','\"\"') AS varchar(4000)) + '\"', '\"' ...
				 FROM PIPP.dbo.VendorAgency" queryout "VendorAgency.csv" -w -t , -T -S UISPRODMSSQL\UISPRODMSSQL
				 
		4) Copy and paste this output into a [bat] file and run it - this will dump/export the tables 
			into a CSV formatted file.
		
Enhancements:
		Could modify so output of [export_object_csv] is ran from within this procedure using
		[xp_cmdshell] (this was causing problems, and you actually have a little more flexibility
		without it).
		
See:	[ utils\sqlserver\loopback_linked_server.sql ]

Author: ???
		Vern Huber - Modified to handle binary data types (e.g. timestamp), as well as other bugs.
		
Caveats / Things to Consider:

		The following should be in place prior to applying/creating this procedure:
		
			EXEC master.dbo.sp_configure 'show advanced options', 1
			RECONFIGURE EXEC master.dbo.sp_configure 'Ad Hoc Distributed Queries', 1
			-- sp_configure 'Ad Hoc Distributed Queries', 1;
			RECONFIGURE;
			GO
		
		Also, the [loopback ] linked server will need to exist.
		
Examples:	See Description.

*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ------------------------------------------------------------------------
if OBJECT_ID( 'dbo.view_Columns', 'V') is NULL
begin
	EXEC sp_ExecuteSQL  N'CREATE VIEW view_Columns AS SELECT '' AS COLUMN_NAME'
	print 'View stub created for: [dbo.view_Columns]...'
end

if OBJECT_ID( 'dbo.export_object_csv', 'P') is NULL
begin
	EXEC sp_ExecuteSQL  N'CREATE PROCEDURE [dbo].[export_object_csv]  as  select 1 as x' 
	print 'Procedure stub created for: [dbo.export_object_csv]...'
end

-- CREATE PROCEDURE [dbo].[export_object_csv]
--
alter PROCEDURE [dbo].[export_object_csv]
	@table_name varchar(255),
	@file_name varchar(1024)
AS 
BEGIN
	DECLARE @column_name varchar(255), @sql_column_names varchar(4000), @sql_columns varchar(4000)
	      , @sql varchar(4000), @db_name varchar(255), @cmd varchar( 1000 )

	SET @db_name = DB_NAME()
	SET @sql_column_names = 'SELECT '
	SET @sql_columns = 'SELECT '
	-- EXEC('ALTER VIEW view_Columns AS SELECT COLUMN_NAME FROM OPENROWSET (''SQLOLEDB'',''Server=(local);TRUSTED_CONNECTION=YES;'',''set fmtonly off exec ' + @db_name + '.dbo.sp_columns ''''' + @table_name + ''''''') AS tbl')
	-- OPENROWSET (''SQLOLEDB'',''Server=(UISprodmssql),DRIVER={SQL Server};UID=SA;PWD=Mssql@08;'',''set fmtonly off exec ' + @db_name + '.dbo.sp_columns ''''' + @table_name + ''''''') AS tbl')
	-- OPENROWSET (''SQLOLEDB'',''Server=(UISprodmssql),DRIVER={SQL Server};UID=SA;PWD=Mssql@08;'',''set fmtonly off exec ' + @db_name + '.dbo.sp_columns ''''' + @table_name + ''''''') AS tbl')
    -- EXEC('ALTER VIEW view_Columns AS SELECT COLUMN_NAME FROM OPENROWSET (loopback,''Server=(local);TRUSTED_CONNECTION=YES;'',''set fmtonly off exec ' + @db_name + '.dbo.sp_columns ''''' + @table_name + ''''''') AS tbl')

	set @cmd = '''set fmtonly off;  exec pipp.dbo.sp_columns ''''' + @table_name + ''''' '  
	set @cmd = 'ALTER VIEW view_Columns AS SELECT COLUMN_NAME FROM  OPENquery (loopback, '+ @cmd +''') AS tbl'
-- print @cmd
	exec ( @cmd  )

	declare @timestamp_flag int
	DECLARE c1 CURSOR FOR SELECT COLUMN_NAME FROM view_Columns
	OPEN c1

	FETCH NEXT FROM c1 INTO @column_name
	WHILE @@FETCH_STATUS = 0 BEGIN
		
		SET @sql_column_names = @sql_column_names + '''\"' + @column_name + '\"'' AS ' + @column_name + ', '
		-- SET @sql_columns = @sql_columns + '''\"'' + CAST(REPLACE(' + @column_name + ',''\"'',''\"\"'') AS varchar(4000)) + ''\"'', '
		
		set @timestamp_flag = 0
		SELECT  @timestamp_flag = count(0)  FROM information_schema.columns C 
		   inner join information_schema.tables  T on c.TABLE_NAME = t.TABLE_NAME
		   and t.TABLE_CATALOG = @db_name  and t.TABLE_SCHEMA = 'dbo'   and data_type = 'timestamp'
		   and t.TABLE_NAME = @table_name  and c.COLUMN_NAME = @column_name
		   
		if ( @timestamp_flag > 0 )
		begin
		   SET @sql_columns = @sql_columns + '''\"'' + CAST( CONVERT( NUMERIC(20,0), '+ @column_name +' + 0 ) as varchar(4000)) + ''\"'', '
		end
		else
		begin
		   SET @sql_columns = @sql_columns + '''\"'' + CAST(REPLACE(' + @column_name + ',''\"'',''\"\"'') AS varchar(4000)) + ''\"'', '
		end

		FETCH NEXT FROM c1 INTO @column_name
	END

	CLOSE c1
	DEALLOCATE c1

	SET @sql_column_names = LEFT(@sql_column_names,LEN(@sql_column_names)-1)
	SET @sql_columns = LEFT(@sql_columns,LEN(@sql_columns)-1) + ' FROM ' + @db_name + '.dbo.' + @table_name

	
	-- SET @sql = 'cd C:\Program Files\Microsoft SQL Server\100\Tools\Binn & bcp "'
	SET @sql = 'bcp "' + @sql_column_names + ' UNION ALL ' + @sql_columns + '" queryout "' + @file_name + '" -w -t , -T -S ' + @@servername


	-- We SHOULD be able to invoke this from the [xp_cmdshell] within sql, but this throws: 
	-- Error = [Microsoft][SQL Server Native Client 10.0]Unable to open BCP host data-file
	--
	-- EXEC master..xp_cmdshell @sql
	--
	-- ...as a work-around, dump CMD to output for capturing and invoke from cmd line.
	--	
	print @sql

END

GO
