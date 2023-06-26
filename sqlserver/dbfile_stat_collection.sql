/*
File:	utils\sqlserver\uis_dbfile_stat_refresh.sql


sys.DATABASES:	


Procedures - see prologue of each utility:
		
	uis_dbfile_stat_refresh() - pop DB file storage stats (for reporting on).
	
	uis_dbfile_stat_rpt() - report on storage usage for each DB (data, logging).
	
	uis_dbfile_stat_run() - invokes refresh and then the reporting (of refreshed results), eg:
		exec dbo.uis_dbfile_stat_run;
		
Job:	[AAA DBfile_Stat_Run]
	
*/
use master;
/* UIS_DB_FILE_STATS - based upon [sys.MASTER_FILES]
... https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-master-files-transact-sql?view=sql-server-ver16

*/
create table master.dbo.UIS_DB_FILE_STATS(
  db_id					INT
, file_id				INT
, run_time				DATETIME		-- daily run pops with date only (not time)
, db_name				NVARCHAR( 256 )
, type_desc				NVARCHAR( 5 )	-- ROW or LOG
, file_size				INT
, file_usage 			INT
, max_size				INT
, file_name				NVARCHAR( 520 )
, basename				NVARCHAR( 256 )
, is_percent_growth		BIT
, CONSTRAINT PK_UIS_DB_FILE_STATS  primary key clustered (  db_id, file_id, run_time )
);
--
grant select, insert, update, delete on dbo.UIS_DB_FILE_STATS to public;

-- =================================================================================
-- create procedure  dbo.UIS_DBFILE_STAT_REFRESH
alter procedure  dbo.UIS_DBFILE_STAT_REFRESH
(
   @v_time		DATETIME = NULL	
   , @v_help	VARCHAR(10) = NULL
)
AS
begin
   set NOCOUNT ON
   
   if ( upper(@v_help) = 'HELP' ) 
   begin
       print '
File:	utils\sqlserver\dbfile_stat_collection.sql

Desc:	This utility refreshes the file usage stats across all the databases using the
		current time or the time passed in.
		
		-2 : @v_help = Help, to print this prologue;
		 0 : Successful refresh of DB file usage stats.
		>0 : Error code of some sort;
		
		Persisting the data is needed because DB file stats can only be retrieved within
		the scope of the DB being looked up for.
		...forcing an iteration across DBs (vs. select ... sys.DATABASES join sys.MASTER_FILES )
		
Note:	At the time of writing this alert, here''s how the data sizing was:

		select max_size, count(0) from sys.MASTER_FILES  group by max_size ;  
		195 files, 0 are fixed in size, 124 (-1) will fill the DB up, and 71 are 2TB.

		
Enhancements:
		
See:	

Author: Vern Huber - Apr. 2023
		
Caveats / Things to Consider:
		
Examples:
		exec dbo.UIS_DBFILE_STAT_REFRESH ;		-- defalut: use date (time truncated)
		
		exec dbo.UIS_DBFILE_STAT_REFRESH @v_help = ''HELP'';	-- provides this HELP prologue

		exec dbo.UIS_DBFILE_STAT_REFRESH @v_time = a_getdate_var;	-- use the current date + time 
';
      return( -2 );
   end;   -- ******************************** END of HELP **************************************

   if ( @v_time is NULL ) 
   begin
	  set @v_time  = dateadd(DAY, datediff(DAY, 0, getdate()), 0) ;
	  
	  -- Guard against same-day-run dupe-key errors (no time provided) - remove previous run
	  delete from  master.dbo.UIS_DB_FILE_STATS  where run_time = @v_time;
   end;
   
   -- Remove old entries (guard against filling up [master] DB...
   delete from  master.dbo.UIS_DB_FILE_STATS  where run_time <  dateadd( DAY, -100, getdate() );
   
   -- Declare variables used by the procedure internally
   declare @cmd				NVARCHAR(1000);
   declare @db_id			INT ;
   declare @db_name 		VARCHAR(50) ;	-- database name 
   --
   declare @db_id_str 		VARCHAR(10) ;	-- database id 
   declare @run_time_str 	VARCHAR(20) ;	-- database run time 
   
   -- Ignore off-line and defunct DBs (state > 6)
   declare a_cursor  CURSOR  for  select  database_id,  name  from master.sys.DATABASES  where state < 6   order by name;
   
   set @run_time_str =   convert(varchar, @v_time, 0) ; 
  
   OPEN a_cursor ;
   fetch next from A_CURSOR  into @db_id, @db_name ;
   --
   while @@FETCH_STATUS = 0
   begin
	  begin  
	    -- Change the DB we are wanting to lookup file info for, or [fileproperty()] will fail...
		-- ...and do this within scope of [use] request
		--
	    set @db_id_str = cast( @db_id as varchar( 10 ) ) ; 

-- Ingore autogrowth ( is_percent_growth != 1 )
	    set  @cmd = 'use ' + @db_name + ';
		insert into master.dbo.UIS_DB_FILE_STATS( 
	     db_id,  file_id,  run_time,  db_name,  type_desc,  file_size,  max_size,  file_usage, file_name, basename, is_percent_growth
		)
		select  '+ @db_id_str +' as db_id, file_id,  cast( '''+ @run_time_str +''' as datetime )  as run_time, '''+ @db_name +''' as db_name, type_desc
		, ( size / 128.0 ) as file_size, max_size, ( cast( fileproperty( name, ''SpaceUsed'') AS INT ) / 128.0 ) as file_usage  
		, physical_name  file_name, name  basename, is_percent_growth
		from master.sys.MASTER_FILES  where type_desc in ( ''ROWS'',''LOG'' ) and database_id = '+ @db_id_str +' ;' ;
		
		print '...'+ @cmd ;

		exec sp_executesql  @cmd ;	-- See prologue for reason commenting out
	  end ;	
	  
	  fetch next from a_cursor  into @db_id, @db_name ;
	  
   end ;	-- end of iterating across all databases
   --
   -- No need to change DB back to [master] - setting only last within scipe of [sp_executesql] cmd

   CLOSE  a_cursor;
   DEALLOCATE  a_cursor;

   return( 0 );
   
-- --------------------------------------------------------------------------------------
ErrorHandler:

   goto ExitProc;  -- ...should not have gotten here, nothing extra to do yet - placeholder
   
-- --------------------------------------------------------------------------------------
ExitProc:
    return( -3 );
	
end ;	--  End of [ dbo.UIS_DBFILE_STAT_REFRESH ]  -- commit



-- =================================================================================
-- create procedure  dbo.UIS_DBFILE_STAT_RPT
alter procedure  dbo.UIS_DBFILE_STAT_RPT
(
   @v_time		DATETIME = NULL	
   , @v_help	VARCHAR(10) = NULL
)
AS
begin
   set NOCOUNT ON
   
   if ( upper(@v_help) = 'HELP' ) 
   begin
       print '
File:	utils\sqlserver\dbfile_stat_collection.sql

Desc:	This utility reports on the DB usage stats for a given date passed in.
	@v_time : Time to to base the reporting on (default is truncated datetime or date only).
	
	@v_help : Print this prologue.
	
	@v_send_to : Where to direct the report to (email wise)
	
Returns:

	-2 : @v_help = Help, to print this prologue;
	 0 : Successful refresh of DB file usage stats.
	>0 : Error code of some sort;
	
For additional detail, see:  exec dbo.UIS_DBFILE_STAT_RPT @v_help = ''HELP'';	

Author: Vern Huber - Apr. 2023
		
Caveats / Things to Consider:

	There were no fixed size DB - so detecting when they''ll fill up a file is remote.
	...the disk will fill up before (most likely).
		
Examples:
		exec dbo.UIS_DBFILE_STAT_RPT ;		-- defalut: use date (time truncated)
		
		exec dbo.UIS_DBFILE_STAT_RPT @v_help = ''HELP'';	-- provides this HELP prologue

		exec dbo.UIS_DBFILE_STAT_RPT @v_time = a_getdate_var;	-- use the current date + time 
		
		exec dbo.UIS_DBFILE_STAT_RPT @v_send_to = ''uisappdevdl@uis.edu'';	-- send to
';
      return( -2 );
   end;   -- ******************************** END of HELP **************************************

   if ( @v_time is NULL ) 
   begin
	  set @v_time  = dateadd(DAY, datediff(DAY, 0, getdate()), 0) ;
   end;
   
   -- Declare variables used by the procedure internally   
   declare @db_name 		VARCHAR( 50 );	-- database name
   declare @type_desc 		VARCHAR( 10 );	-- database name
   declare @f_size			DECIMAL( 10, 2); 
   declare @f_usage			DECIMAL( 10, 2); 
   declare @p_unused_str	VARCHAR( 10 ); 
   declare @run_time_str	VARCHAR( 20 ); 
   declare @subject_str		VARCHAR( 50 ) = ' DB storage stats: '+ @@SERVERNAME ;
   declare @body_msg		NVARCHAR( MAX ); 
   declare @body_db_items	NVARCHAR( MAX ); 

   -- DBs to report on - except autogrowth (is_percent_growth = 1) and system DBs
   --
   declare a_cursor  CURSOR  for
      select top 20  f.*  from ( 
	     select  db_name,  type_desc,  cast( sum( file_usage ) as decimal( 10,2 )) f_usage
	     from master.dbo.UIS_DB_FILE_STATS  
		 where run_time = @v_time  and db_name NOT IN ('distribution', 'master', 'model', 'msdb', 'tempdb') 
		 group by db_name, type_desc  
	  )  F  
	  order by  f.f_usage  desc ;
	  
   set @run_time_str = convert(varchar, @v_time, 0) ; 
   set @body_db_items = ''; 

   OPEN a_cursor ;
   FETCH next from A_CURSOR  into  @db_name,  @type_desc,  @f_usage;
   --
   while @@FETCH_STATUS = 0
   begin
	  -- set @p_unused_str = cast( format( round( ( 1 - ( @f_usage / @f_size ) ) * 100 , 2, 2 ), '0.##') as varchar( 10 ) );

	  set @body_db_items = concat( @body_db_items, '<tr> <td> ', @db_name, ' </td><td> &nbsp;',  @type_desc, ' &nbsp;</td>');
	  set @body_db_items = concat( @body_db_items, '&nbsp;<td aling=right>', cast( round( @f_usage, 12, 2 ) as varchar( 12 ) ), ' &nbsp;</td> ' );
	  set @body_db_items = concat( @body_db_items, ' </tr>', CHAR(10)+CHAR(13) );

 -- print 'unused space ' + @p_unused_str + ' for db ' + @db_name  + @body_db_items;

	  FETCH next from A_CURSOR  into  @db_name,  @type_desc,  @f_usage;
	  
   end ;	-- end of iterating across all DB usage stats for @v_time
   
--  print 'BODY ENTRIES: '+ @body_db_items; 

   -- Line continuation needs to occur within a string literal.
   set @body_msg = '<table cellpadding="2" cellspacing="2" border="1" > '+  CHAR(13)+CHAR(10)  +'
   <tr><th colspan="3" align="center">Table Space Usage Metrics (top users, high-to-low)<br/></th></tr>'+  CHAR(13)+CHAR(10)  +'
   <tr><th> DB </th> <th> Type </th> <th> MB Used </th> </tr>
   ' +  @body_db_items  +'</table>'+  CHAR(13)+CHAR(10)   +'
   <p>This email was generated by: [uis_dbfile_stat_rpt()] located at: [utils/sqlserver/dbfile_stat_collection.sql].</p>
   ' +'<p>Data is refreshed by: [uis_dbfile_stat_refresh()] located at: [utils/sqlserver/dbfile_stat_collection.sql].</p>'  ;

--  print @body_msg; 
  
   exec msdb.dbo.uis_sendmail @to = 'vhube3@uis.edu', @subject = @subject_str, @body = @body_msg, @group_id = 1001 ;

   CLOSE  a_cursor;
   DEALLOCATE  a_cursor;

   return( 0 );
   
-- --------------------------------------------------------------------------------------
ErrorHandler:

   goto ExitProc;  -- ...should not have gotten here, nothing extra to do yet - placeholder
   
-- --------------------------------------------------------------------------------------
ExitProc:
    return( -3 );
	
end ;	--  End of [ dbo.UIS_DBFILE_STAT_RPT ]  -- commit


-- =================================================================================
-- create procedure  dbo.UIS_DBFILE_STAT_RUN
alter procedure  dbo.UIS_DBFILE_STAT_RUN
(
   @v_time		DATETIME = NULL	
   , @v_help	VARCHAR(10) = NULL
)
AS
begin

	exec dbo.UIS_DBFILE_STAT_REFRESH ;
	exec dbo.UIS_DBFILE_STAT_RPT ;
	
end ;	--  End of [ dbo.UIS_DBFILE_STAT_RUN ]  -- commit

