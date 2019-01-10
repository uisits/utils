/*
File:	utils\sqlserver\get_filesize.sql

		!*!*!* SEE PROLOGUE BELOW *!*!*!*
*/
USE [msdb]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

if OBJECT_ID( 'dbo.get_filesize', 'P') is NULL
begin
	EXEC sp_ExecuteSQL  N'CREATE PROCEDURE [dbo].[get_filesize]  as  select 1 as x' 
	print 'View stub created for: [dbo.get_filesize]'
end
GO
--
ALTER PROCEDURE [dbo].[get_filesize]
   @filename		NVARCHAR(1000)	= 'HELP' -- to get  prologue
AS
BEGIN
   SET NOCOUNT ON
   
   if (  @filename is NULL  or upper(@filename) = 'HELP'  or @filename = '' ) 
   begin
       print '
File:	utils\sqlserver\get_filesize.sql

Desc:	This utility accepts a [filename] as input, and returns an integer as follows:

		-2 : Help Prologue returned;
		
		-1 : File does not exist;
		
		 0 : File exist, but is empty;
		
		>0 : File exist, and the value is the size of the file;
		
Note:	
		
Enhancements:
		
See:	

Author: Vern Huber - Feb. 2017
		
Caveats / Things to Consider:
		
Examples:
		exec msdb.dbo.get_filesize;		<-- provides this HELP prologue

		exec @myfile_sz = msdb.dbo.get_filesize ''L:\some_dir\some_filename.txt'';
'
      return -2;
   end
-- ******************************** END of HELP **************************************

   -- Declare variables used by the procedure internally
   declare @cmd				varchar(1000);
   declare @result_txt		varchar(1000);
   declare @ret_code		int;
	
  -- Master.dbo...
   exec xp_fileexist @filename, @ret_code OUT ;
   if @ret_code = 1
   begin
   
      if exists ( select * from sys.objects  where object_id = OBJECT_ID(N'[dbo].[#tempcmd]') AND type in (N'U') ) 
         drop table [dbo].[#tempcmd];      
      create table #tempcmd( cmd_results varchar(1000) );
	  
      -- To bad [xp_filesize] is not readily available:  exec xp_filesize @filename, @ret_code OUT ;
	  set @cmd = 'type '+ @filename +'  | find "" /c /v';
	  -- exec @retsults_txt = xp_cmdshell @cmd;
      insert into #tempcmd execute xp_cmdshell  @cmd;
	  
	  select top 1 @result_txt = cmd_results  from #tempcmd 
	  -- select OBJECT_NAME(@@PROCID) + ': Result is --> '+ @result_txt; 
	  
	  select @ret_code = case when @result_txt is NULL  then 0  else CAST( @result_txt as int ) end;
	  
	  -- select OBJECT_NAME(@@PROCID) + ': Result parsed is '+ CAST(@ret_code as varchar(10));
	  
   end;
   else
   begin
      select OBJECT_NAME(@@PROCID) + ': file existence check failed.';
	  set @ret_code = -1;
   end;

   return( @ret_code );
   
-- --------------------------------------------------------------------------------------
ErrorHandler:

   goto ExitProc;  -- ...should not have gotten here, nothing extra to do yet - placeholder
   
-- --------------------------------------------------------------------------------------
ExitProc:
	set @ret_code = -3;
    return( @ret_code );
	
end  --  End of [ dbo.get_filesize ]  -- commit
