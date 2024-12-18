/*
File:	utils\sqlserver\uis_sendmail.sql

<<< For prologue/help page - see beginning of procedure definition >>>

*/
USE [msdb]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

/* !!!!!!!!!!!!!!!!!  A DB profile [uisappdev] must exist for sending email with !!!!!!!!!!!!
...and [db_send_mail] must be enabled

USE MASTER 
GO 
SP_CONFIGURE 'show advanced options', 1 
RECONFIGURE WITH OVERRIDE 
GO 

-- Enable Database Mail XPs Advanced Options in SQL Server 
SP_CONFIGURE 'Database Mail XPs', 1 
RECONFIGURE WITH OVERRIDE 
GO 

SP_CONFIGURE 'show advanced options', 0 
RECONFIGURE WITH OVERRIDE 
GO

use MSDB;
GRANT execute  ON OBJECT::dbo.uis_sendmail TO sandal;
GRANT execute  ON OBJECT::dbo.sp_send_dbmail TO sandal;

-- Grant EXECUTE permission on sp_send_dbmail
GRANT EXECUTE ON sp_send_dbmail TO sandal;

*/
-- DROP PROCEDURE [dbo].[uis_sendmail]
-- GO
--
if OBJECT_ID( 'dbo.uis_sendmail', 'P') is NULL
begin
	EXEC sp_ExecuteSQL  N'CREATE PROCEDURE [dbo].[uis_sendmail]  as  select 1 as x' 
	print 'View stub created for: [dbo.uis_SENDMAIL]'
end
GO
--
ALTER PROCEDURE [dbo].[uis_sendmail]
   @profile_name                 sysname		= 'uisappdev'        
   , @to                         VARCHAR(MAX)	= NULL	-- pass as is [recipients]
   , @cc                         VARCHAR(MAX)	= NULL	-- pass as is [copy_recipients] - semicolon [;] delimited
   , @bcc                        VARCHAR(MAX)	= NULL	-- pass as is [blind_copy_recipients]
   , @subject                    NVARCHAR(255)	= '-- subject not provided --'
   , @body                       NVARCHAR(MAX)	= NULL 
   , @group_id					 DECIMAL(18, 0)	= 10	-- Default GLOBAL param set;
   , @body_format                VARCHAR(20)	= 'html'
   , @importance                 VARCHAR(6)		= 'NORMAL'
   , @sensitivity                VARCHAR(12)	= 'NORMAL'
   , @file_attachments           NVARCHAR(MAX)	= NULL 
   , @query                      NVARCHAR(MAX)	= NULL
   , @execute_query_database     sysname 		= NULL 
   , @attach_query_result_as_file BIT          	= 0
   , @query_attachment_filename  NVARCHAR(260) 	= NULL  
   , @query_result_header        BIT           	= 1
   , @query_result_width         INT           	= 256           
   , @query_result_separator     CHAR(1)       	= ' '
   , @exclude_query_output       BIT           	= 0
   , @append_query_error         BIT           	= 0
   , @query_no_truncate          BIT           	= 0
   , @query_result_no_padding    BIT          	= 0
   , @mailitem_id                INT           	= NULL	OUTPUT
   , @from_address               VARCHAR(max)  	= NULL
   , @reply_to                   VARCHAR(max)  	= NULL
   , @application_error          BIT           	= 0
   , @send_autonomously          BIT           	= 0
   , @run_type					 NVARCHAR(10)	= 'HELP' -- to get  prologue
AS
BEGIN
   SET NOCOUNT ON
   
   if ( @to is not NULL  or @to = '' )	-- Only provide HELP prologue if no TO info passed in.
   begin
       set @run_type = 'NO HELP'
   end
   
   if (  @run_type is NULL  or upper(@run_type) = 'HELP'  or @run_type = '' ) 
   begin
       print '
File:	utils\sqlserver\uis_sendmail.sql

Desc:	Wrapper for sending email via the db.

		[ sp_send_dbmail ] - is the underlying db utility that this utility uses,
		but a successful send request is predicated on a successful transaction.
		
		Further, autonomous transactions are not directly supported in SQL Server -
		result: an excpetion case that results in a rollback, will discard the
		sending of the email.  See [ send_autonomously ] flag to get around this.
		
		[ send_autonomously ] - Flag indicating how to send email - i.e.:
		
		0 or NULL : send email within scope of transaction (if a transaction is
			present).  If the transaction fails (later on) the email does NOT
			get sent ([sp_send_dbmail] couples itself to an open transaction).
			
		1 : send email autonomous of transaction (if a transaction is present).
			If the transaction fails (later on) the email IS still sent.
			A [loopback] linked db server is used to achieve this
		
		[ application_error ] - Flag indicating that the caller wants the email to
		be sent as an application/system error email (i.e. email will be sent to the
		address stored in [dbo.uis_SYS_PARAM_LKP] for ( param_cd = ERROR_EMAIL_TO ).
		
		0 or NULL : Caller needs to provide to-address.
			
		1 : Error type of email - ERROR_EMAIL_TO will be used.
		
		[group_id] - Optional;  Also view as an Application ID (see Application table).

			If not provided, default values defined in [UIS_SYS_PARAM_LKP.param_id] = 10
			are used.
			
			If passed in, then those entries set with ( param_id = group_id )
			will be used.
			
			Applications should use their Application ID (so that it can be suffixed
			to the end of the subject (as an identification scheme).
		
Note:	All emails not originating from a production sys, has the subject prefixed 
		with the db servername - e.g.: "[@@servername] ".  
		
Enhancements:
		___ Log all requests to a table (for auditing), or just success cases
			Difference being autonomous requests - others might be backed out.
			
		___ Convert to Dynamic SQL to allow for formatting a SQL w/ only known
		values passed in.  Code was originally written this way - but complications
		w/ escaping special chars expanded the scope of things.
		[ D-SQL ] marks line/code blocks needed to support this enhancement.
		
		Callers can override the common parameter value (param_id = 10) by adding
		their own value as passed in via [group_id] (for just the ones they want to).
		
See:	[ utils\sqlserver\loopback_linked_server.sql ]

Debug:	SELECT * FROM msdb..sysmail_mailitems WHERE sent_date > DATEADD(DAY, -1,GETDATE()) 
		order by last_mod_date desc
		
		Other helpful email db objects:
		
		...dbo.sysmail_log  (see ./uis_sendmail_log.sql)
        ...msdb.dbo.sysmail_allitems  where  sent_date > DATEADD(DAY, -1,GETDATE()) 
		...msdb.dbo.sysmail_event_log  where  log_date > DATEADD(DAY, -1,GETDATE()) ;
		...msdb.dbo.sysmail_faileditems  where  send_request_date > DATEADD(DAY, -1,GETDATE()) ;
		...msdb.dbo.sysmail_unsentitems 

Author: Vern Huber
		
Caveats / Things to Consider:

		Defaults used below were taken from [ dbo.sp_send_dbmail ] at the time of
		coding this utility, and might not match the current defaults.
		See [ Enhancements ].
		
		May need to grant permissions (to allow usage of this utility):
		GRANT EXECUTE on msdb.dbo.uis_sendmail to PUBLIC
		GRANT select on msdb.dbo.uis_sys_param_lkp to PUBLIC  
		
		If testing from SSMS, and you have explicit transactions set - remember to commit
		in order to release the email.
		
Examples:
		exec msdb.dbo.uis_sendmail @to = ''vhube3@uis.edu'', @subject = ''General Campus...''
			, @body = ''<b>HOWDY!</b>'', @body_format = ''html''
			
		exec msdb.dbo.uis_sendmail @to = ''vhube3@uis.edu'', @subject = ''ITS Mtce...''
			, @body = ''<b>ITS Mtce</b> Your attention please...'', @body_format = ''html'', @group_id = 11
		
		Eg of using the [FROM ADDRESS]:
		exec msdb.dbo.uis_sendmail @to = ''vhube3@uis.edu'', @subject = ''Scholarship Submission Reminder''
			, @from_address = ''UIS Office of Financial Assistance <finaid@uis.edu>''
			, @body_format = ''html'', @group_id = 1005, @body = ''...yadda, yadda...'' 
 
 
		exec msdb.dbo.uis_sendmail	<-- to get this prolgue/help page.
'
      return 1;
   end

-- ******************************** END of HELP **************************************

	--Declare variables used by the procedure internally
    DECLARE	@subject_str		NVARCHAR( 2000 )
			, @subject_prefix   NVARCHAR(  100 ) = '[' + @@servername + '] '
			, @app_id_suffix	NVARCHAR(  100 ) = '<style> font.its_tail { color:grey;font-size:7pt; } </style><font class="its_tail">(appId = ' + cast( @group_id as nvarchar(20) ) +' ) ' -- </font> was print out the partial end tag so I just removed it.
			, @body_str			VARCHAR( MAX )
			, @email_from		NVARCHAR(  250 ) = 'undefined_email@uis.edu'	-- this should get overwritten
			, @error_email_msg	NVARCHAR( 1000 ) = '-- undefined generated message --'	-- this should get overwritten
			, @error_email_to	NVARCHAR(  250 ) = 'vhube3@uis.edu'	-- this should get overwritten
			, @platform			NVARCHAR( 100 )
			, @html_head        VARCHAR(MAX)  = ''
			, @html_tail        VARCHAR(MAX)  = ''
			, @param_err		VARCHAR(1)		= 'N'
			-- , @sql_cmd			NVARCHAR( 4000 )  -- D-SQL
			, @srvr_flag		INT
			, @param_cnt		INT = 0
			, @rc				INT
	
	-- Make sure that the PARAMETER Lookup table 
	if OBJECT_ID( 'dbo.uis_sys_param_lkp', 'U') is NULL  and OBJECT_ID( 'dbo.uis_sys_param_lkp', 'V') is NULL
	begin
		select @subject_str = @subject_prefix + 'ALERT: [msdb.dbo.UIS_SYS_PARAM_LKP] missing in DB'
			, @body_str = 'The DB utility [msdb.dbo.uis_sendmail] relies on [msdb.dbo.UIS_SYS_PARAM_LKP] being defined for'
			+ ' configuration purposes, but it does not exist in DB ' 
			+ @@servername + ' (' + convert( varchar, getdate()) + ')' 
			+ char( 10 ) + char( 10 )
			+ 'Remember to define [msdb.dbo.UIS_SYS_PARAM_LKP] and populate entries for: EMAIL_FROM,  ERROR_EMAIL_MSG,  ERROR_EMAIL_TO'

		exec dbo.sp_send_dbmail  @profile_name = @profile_name, @recipients=@error_email_to, @subject=@subject_str, @body=@body_str
	end
	else	-- object exist...
	begin 
		-- Grab value for [GROUP_ID] passed - if it's been defined, else use the default global value
		-- TOP 1 is enforced by setting default of 10 case to 999999;
		--
		select top 1 @platform = t.param_value,  @param_cnt = count(0)  from ( 
			select param_value, param_id as order_by  from dbo.uis_SYS_PARAM_LKP  where  param_id = @group_id and  PARAM_CD = 'PLATFORM_TYPE'
			union select param_value, 999999 as order_by  from dbo.uis_SYS_PARAM_LKP  where  param_id = 10  and  PARAM_CD = 'PLATFORM_TYPE'
		) t  group by param_value, order_by  order by order_by
		if ( @param_cnt != 1 ) begin select @param_err = 'Y'; end
		
		select top 1 @email_from = t.param_value,  @param_cnt = count(0)  from ( 
			select param_value, param_id as order_by from dbo.uis_SYS_PARAM_LKP  where  param_id = @group_id and  PARAM_CD = 'EMAIL_FROM'
			union select param_value, 999999 as order_by  from dbo.uis_SYS_PARAM_LKP  where  param_id = 10  and  PARAM_CD = 'EMAIL_FROM'
		) t  group by param_value, order_by  order by order_by
		if ( @param_cnt != 1 ) begin select @param_err = 'Y'; end
		
		select top 1 @error_email_msg = t.param_value,  @param_cnt = count(0)  from ( 
			select param_value, param_id as order_by from dbo.uis_SYS_PARAM_LKP  where  param_id = @group_id and  PARAM_CD = 'ERROR_EMAIL_MSG'
			union select param_value, 999999 as order_by  from dbo.uis_SYS_PARAM_LKP  where  param_id = 10  and  PARAM_CD = 'ERROR_EMAIL_MSG'
		) t  group by param_value, order_by  order by order_by
		if ( @param_cnt != 1 ) begin select @param_err = 'Y'; end
		
		select top 1 @error_email_to = t.param_value,  @param_cnt = count(0)  from ( 
			select param_value, param_id as order_by from dbo.uis_SYS_PARAM_LKP  where  param_id = @group_id and  PARAM_CD = 'ERROR_EMAIL_TO'
			union select param_value, 999999 as order_by  from dbo.uis_SYS_PARAM_LKP  where  param_id = 10  and  PARAM_CD = 'ERROR_EMAIL_TO'
		) t  group by param_value, order_by  order by order_by
		if ( @param_cnt != 1 ) begin select @param_err = 'Y'; end
		
		select top 1 @html_head = t.param_value,  @param_cnt = count(0)  from ( 
			select param_value, param_id as order_by from dbo.uis_SYS_PARAM_LKP  where  param_id = @group_id and  PARAM_CD = 'HTML_HEAD'
			union select param_value, 999999 as order_by  from dbo.uis_SYS_PARAM_LKP  where  param_id = 10  and  PARAM_CD = 'HTML_HEAD'
		) t  group by param_value, order_by  order by order_by
		if ( @param_cnt != 1 ) begin select @param_err = 'Y'; end
		
		select top 1 @html_tail = t.param_value + @app_id_suffix,  @param_cnt = count(0)  from ( 
			select param_value, param_id as order_by from dbo.uis_SYS_PARAM_LKP  where  param_id = @group_id and  PARAM_CD = 'HTML_TAIL'
			union select param_value, 999999 as order_by  from dbo.uis_SYS_PARAM_LKP  where  param_id = 10  and  PARAM_CD = 'HTML_TAIL'
		) t  group by param_value, order_by  order by order_by
		if ( @param_cnt != 1 ) begin select @param_err = 'Y'; end
			
		if ( @param_err = 'Y' )
		begin
			-- 1 or more of the required parameters is missing
			select @subject_str = @subject_prefix + 'ALERT: [msdb.dbo.UIS_SYS_PARAM_LKP] parameters missing in DB'
				, @body_str = 'The DB utility [msdb.dbo.uis_sendmail] has discovered that one or more of the following parameters'
				+ char( 10 ) + char( 10 ) + ' { EMAIL_FROM, ERROR_EMAIL_MSG, ERROR_EMAIL_TO, HTML_HEAD, HTML_TAIL } '
				+ char( 10 ) + char( 10 ) + 'are/is missing in [msdb.dbo.uis_SYS_PARAM_LKP] in the DB '	
				+ @@servername + ' (' + convert( varchar, getdate()) + ') <br/><br/>' 
				+ char( 10 ) + char( 10 )
				+ 'Remember to populate entries for: EMAIL_FROM,  ERROR_EMAIL_MSG,  ERROR_EMAIL_TO, HTML_HEAD, HTML_TAIL'

			exec dbo.sp_send_dbmail  @profile_name = @profile_name, @recipients=@error_email_to, @subject=@subject_str, @body=@body_str
		end
	end

	-- Make sure that the LOOPBACK server exists...
	select @srvr_flag = COUNT(0)  from master..sysservers where srvname = 'loopback'
	IF  (  @srvr_flag = 0 )
	begin 
		select @send_autonomously = 0	-- ...unavailable - ignore request for autonomous sending
		
		-- Send alert that the LOOPBACK server is not present, and needs to be.
		select @subject_str = @subject_prefix + 'ALERT: Missing DB Link [LOOPBACK] in DB'
			, @body_str = 'The DB utility [dbo.uis_sendmail] requires the loopback linked server to be defined'
			+ ' in order to send email out autonomously - and the [LOOPBACK] DB Link is not defined in DB ' 
			+ @@servername + ' (' + convert( varchar, getdate()) + ')' 
			+ char( 10 ) + char( 10 )
			+ 'See [ utils\sqlserver\loopback_linked_server.sql ] on how to populate it.'
		exec dbo.sp_send_dbmail  @profile_name = @profile_name, @recipients=@error_email_to, @subject=@subject_str, @body=@body_str
	end

	-- See if callers wants the ERROR_EMAIL_TO to be used...
	if ( @application_error = 1 )
	begin
		select @to = @error_email_to
	end	
	
	-- Make it easy to identify Non-Production emails, by adding the DB servername to the email subject (not production)
	-- ...and if we're dealing with the EXCEPTION request [12], account for that as well.
	--
	if ( @platform != 'PRODUCTION' )
    begin 
	   if @group_id = 12
	   begin
		   select @subject_prefix = @subject_prefix +' EXCEPTION: '
	   end
	end
	else
	begin
	   select @subject_prefix = ''
	   
	   -- For ITS exceptions, prefix the subject.
	   if @group_id = 12
	   begin
          select @subject_prefix = 'EXCEPTION: '
	   end
	end
	select  @subject = @subject_prefix + @subject
	
	if ( @body_format = 'html' )
	begin
		select @body_str = '<!-- START of HTML HEAD -->'+ @html_head +'<!-- END of HTML HEAD -->'+ @body +'<!-- START of HTML TAIL -->'+ @html_tail +'<!-- END of HTML TAIL -->'
	end	
    else
	begin
		select @body_str = @body
	end
	
	-- Format the base cmd and required fields...
	-- D-SQL: select @sql_cmd = N'msdb.dbo.sp_send_dbmail  @recipients = [' + @to + ']' + N', @subject = [' + @subject  +']'
	if ( @send_autonomously = 1 )
	begin
		-- D-SQL: select @sql_cmd = N'loopback.' + @sql_cmd
		exec LOOPBACK.msdb.dbo.sp_send_dbmail @profile_name = @profile_name, @recipients = @to, @copy_recipients = @cc
	    , @blind_copy_recipients = @bcc, @subject = @subject, @body = @body_str, @body_format = @body_format
	    , @importance = @importance, @sensitivity = @sensitivity, @file_attachments = @file_attachments
		, @query = @query, @execute_query_database = @execute_query_database, @attach_query_result_as_file = @attach_query_result_as_file
	    , @query_attachment_filename =  @query_attachment_filename, @query_result_header = @query_result_header
        , @query_result_width = @query_result_width, @query_result_separator = @query_result_separator
        , @exclude_query_output = @exclude_query_output, @append_query_error = @append_query_error, @query_no_truncate = @query_no_truncate
        , @query_result_no_padding = @query_result_no_padding, @mailitem_id = @mailitem_id, @from_address = @from_address
        , @reply_to = @reply_to
	end
	else	-- Request to send email within callers transaction
	begin
		exec msdb.dbo.sp_send_dbmail @profile_name = @profile_name, @recipients = @to, @copy_recipients = @cc
	    , @blind_copy_recipients = @bcc, @subject = @subject, @body = @body_str, @body_format = @body_format
	    , @importance = @importance, @sensitivity = @sensitivity, @file_attachments = @file_attachments
		, @query = @query, @execute_query_database = @execute_query_database, @attach_query_result_as_file = @attach_query_result_as_file
	    , @query_attachment_filename =  @query_attachment_filename, @query_result_header = @query_result_header
        , @query_result_width = @query_result_width, @query_result_separator = @query_result_separator
        , @exclude_query_output = @exclude_query_output, @append_query_error = @append_query_error, @query_no_truncate = @query_no_truncate
        , @query_result_no_padding = @query_result_no_padding, @mailitem_id = @mailitem_id, @from_address = @from_address
        , @reply_to = @reply_to
	end
	
/* D-SQL: WARNING - SPECIAL CHARACTERS NEEDED TO BE ESCAPED - or run time failures will occur.
	...and the text passed is not structured/controlled.
	
	-- ...now add optional clauses.
	select @sql_cmd = @sql_cmd 
		+ case when @body is NULL                        then N' ' else N', @body = [' + @body  +']' end
		+ case when @body_format is NULL                 then N' ' else N', @body_format = [' + @body_format +']'  end
		+ case when @cc is NULL                          then N' ' else N', @copy_recipients = [' + @cc + ']' end
		+ case when @bcc is NULL                         then N' ' else N', @blind_copy_recipients  =  [' + @bcc + ']'  end
		+ case when @importance is NULL                  then N' ' else N', @importance = [' + @importance + ']'  end
		+ case when @sensitivity is NULL                 then N' ' else N', @sensitivity = [' + @sensitivity + ']'  end
		+ case when @file_attachments is NULL            then N' ' else N', @file_attachments = [' + @file_attachments + ']'  end
		+ case when @query is NULL                       then N' ' else N', @query = [' + @query + ']'  end
		+ case when @execute_query_database is NULL      then N' ' else N', @execute_query_database = [' + @execute_query_database + ']'  end
		+ case when @attach_query_result_as_file is NULL then N' ' else N', @attach_query_result_as_file = '
																			+ convert( varchar, @attach_query_result_as_file )  end
		+ case when @query_attachment_filename is NULL   then N' ' else N', @query_attachment_filename = [' + @query_attachment_filename + ']'  end
		+ case when @query_result_header is NULL         then N' ' else N', @query_result_header = ' 
																			+ convert( varchar, @query_result_header)  end
		+ case when @query_result_width is NULL          then N' ' else N', @query_result_width = ' 
																			+ convert( varchar, @query_result_width )  end
		+ case when @query_result_separator is NULL      then N' ' else N', @query_result_separator = [' + @query_result_separator + ']'  end
		+ case when @append_query_error is NULL          then N' ' else N', @append_query_error = ' 
																			+ convert( varchar, @append_query_error )  end
		+ case when @query_no_truncate is NULL           then N' ' else N', @query_no_truncate  = ' 
																			+ convert( varchar, @query_no_truncate )  end
		+ case when @query_result_no_padding is NULL     then N' ' else N', @query_result_no_padding = ' 
																			+ convert( varchar, @query_result_no_padding )  end
		+ case when @mailitem_id is NULL                 then N' ' else N', @mailitem_id = '
																			+ convert( varchar, @mailitem_id )  end
		+ case when @from_address is NULL                then N' ' else N', @from_address = [' + @from_address + ']'  end
		+ case when @reply_to is NULL                    then N' ' else N', @reply_to  = [' + @reply_to + ']'  end
		+ case when @profile_name is NULL                then N' ' else N', @profile_name = [' + @profile_name + ']'  end
		
	-- Invoke [ sp_send_dbmail ] request
	exec sp_executesql @sql_cmd
*/
    select @rc = @@ERROR
	
    -- All done OK
    goto ExitProc;

-- --------------------------------------------------------------------------------------
ErrorHandler:
	-- Nothing extra to do for now - placeholder
	
-- --------------------------------------------------------------------------------------
ExitProc:

    RETURN (@rc)
	
END  --  End of [ dbo.uis_SENDMAIL ]  -- commit
