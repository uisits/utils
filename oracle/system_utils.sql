/* 
File:	utils/oracle/system_utils.sql 
 
Desc:	Oracle utilities commonly needed by the [system] account;
		
		Defined in [uis_utils]
		
Utilities:	
		get_storage_metrics( send_to ) => generates usage and sends the results in email.
		
See:	./system_objects.sql
	
Author:	Vern Huber - May 16, 2022

Enhancements:
		TBD
		
*/

-- ==========================  JOBs =====================================================

-- Run job:		exec DBMS_SCHEDULER.run_job('uis_utils.UTILS_STORAGE_METRICS');
-- Drop job:	exec DBMS_SCHEDULER.drop_job('uis_utils.UTILS_STORAGE_METRICS');
--
-- RUN ON:  oraprod, oratest, oradept, oracle (student)
--
BEGIN
   DBMS_SCHEDULER.CREATE_JOB (
      job_name => 'uis_utils.UTILS_STORAGE_METRICS', job_type => 'PLSQL_BLOCK'
      , job_action		=> 'begin   uis_utils.get_storage_metrics( ''vhube3@uis.edu'' );  end;'
      , start_date           => '17-MAY-22 7.31.00AM'
      , repeat_interval      => 'FREQ=DAILY' 
      , end_date             => NULL						-- '15-JAN-99 1.00.00AM US/Pacific',
      , enabled =>  TRUE,  comments => 'UTILS: uis_utils.GET_STORAGE_METRICS'
   );
END;


-- ==========================  Code =====================================================
--
-- exec uis_utils.get_storage_metrics( 'vhube3@uis.edu' ); 
--
create or replace procedure  uis_utils.get_storage_metrics( send_to  	in varchar2 )
is
		msg_body			CLOB;
		tr_rows				CLOB;		
		this_instance		varchar2(100);
		this_host			varchar2(100);		
begin

	declare 
		cursor size_cur  is  select * from uis_utils.STORAGE_METRICS  order by percent_free asc ;

		a_rec	size_cur%rowtype;
	begin
		open size_cur;
		loop	
			fetch size_cur into a_rec;
			exit when size_cur%NOTFOUND;
				
			-- Build html table row/record...
			tr_rows := tr_rows ||'<tr><td>&nbsp;'|| a_rec.tablespace_name ||'</td><td align="right">&nbsp;'|| a_rec.used_space ||'</td><td align="right">&nbsp;'
				   || a_rec.free_space ||'</td><td align="right">&nbsp;'|| a_rec.total_space ||'</td><td align="center">&nbsp;'|| a_rec.percent_free ||'</td></tr>';
		end loop;
		close size_cur;
	end;

	-- Get the server and instance name...
	select lower( host_name ), lower( instance_name ) into this_host, this_instance from v$instance;

	-- Preface message and begin and end the table...
	--
	msg_body := '<p><br/>The following is the storage usage (in MB) for the Oracle DB instance [<b>'|| this_instance ||'</b>] on server [<b>'|| this_host 
	   ||'</b>] - as of '|| to_char( sysdate, 'HH24:MI MM/DD/YYYY' ) ||'. </p>'
	   ||'<table cellpadding="2" cellspacing="2" border="1" >'
	   ||'<tr><th colspan="5" align="center">Table Space Usage Metrics <br/></th></tr>'
	   ||'<tr><th>Table Space</th><th>Used Space</th><th>Free Space</th><th>Total Space</th><th>Percent Free</th></tr>'
	   || tr_rows 
	   ||'</table><p>This email was generated by: [uis_utils.get_storage_metrics()] located at: [utils/oracle/system_utils.sql], using objects defined in  [utils/oracle/system_objects.sql].</p>';

	uis_utils.uis_sendmail.send_html( to_list => send_to, subject => 'DB storage metrics for: '|| this_instance, body_of_msg => msg_body, group_id => 1001 );
	
	EXCEPTION
	when others then
	   rollback;
	   dbms_output.put_line( SQLERRM ||': '|| SQLERRM );
  
end;	-- of get_storage_metrics()
--
