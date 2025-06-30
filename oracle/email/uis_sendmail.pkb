/*
File:	utils/oracle/uis_sendmail.pkb

Desc:	Standardized email wrapper for sending UIS related emails allowing for customization
		via UIS_SYS_PARAM_LKP (entries for header and footer per Application).
		
		!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		
		This SAME UTILITY CAN BE APPLIED on each Oracle instance server, but it does rely 
		on underlying DB objects, e.g.:
		
		uis_utils.UIS_SYS_PARAM_LKP | team.ACT_APP_PARAM_LKP - see GIT [utils/oracle] 
		...and [CDM/department/uis_utils] for background information.
		
		!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	

Note:	For UIS email, the sending server (hosting the DB) will need to be white listed in the exchange server [ smtp.uis.edu ].

		As of Oracle 11g, external/network resources are controlled thru Fine Grain Access or ACLs.  So you need to:

		-- exec DBMS_NETWORK_ACL_ADMIN.drop_acl ( acl => '/sys/acls/utl_smtp.xml');
  
		alter system set smtp_out_server= 'smtp.uis.edu';
		exec DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(acl => 'utl_smtp.xml',description => 'send_mail ACL',principal => 'PUBLIC',is_grant => true,privilege => 'connect');
		exec DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(acl => 'utl_smtp.xml',principal => 'PUBLIC',is_grant  => true,privilege => 'connect');
		exec DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(acl => 'utl_smtp.xml',host => 'smtp.uis.edu', lower_port => 25, upper_port => 25 );
		commit;

...CHANGES 2/11/2022 to accomadate coming switchover to ProofPoint:
...worked on OraTest 
		alter system set smtp_out_server= 'smtp-pod.uis.edu';
		exec DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(acl => 'utl_smtp.xml',description => 'send_mail ACL',principal => 'PUBLIC',is_grant => true,privilege => 'connect');
		exec DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(acl => 'utl_smtp.xml',principal => 'PUBLIC',is_grant  => true,privilege => 'connect');
		exec DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(acl => 'utl_smtp.xml',host => 'smtp-pod.uis.edu', lower_port => 25, upper_port => 25 );
		commit;
...apply pakcage change, to: send_html();

...CHANGES for MAILHOG (Docker uses) - allows per app to select which mailserver to use
		-- No need to reset SMTP out for everyone...
		exec DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(acl => 'utl_smtp_docker.xml',description => 'send_mail ACL',principal => 'PUBLIC',is_grant => true,privilege => 'connect');
		exec DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(acl => 'utl_smtp_docker.xml',principal => 'PUBLIC',is_grant  => true,privilege => 'connect');
		exec DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(acl => 'utl_smtp_docker.xml',host => 'uisdocker3.uisad.uis.edu', lower_port => 1025, upper_port => 1025 );
		commit;
		
		
		col HOST for a45
		SELECT host, lower_port, upper_port, privilege, status FROM   user_network_acl_privileges;

		COLUMN acl FORMAT A30
		COLUMN principal FORMAT A30
		SELECT acl,  principal,  privilege,  is_grant, TO_CHAR(start_date, 'DD-MON-YYYY') AS start_date, TO_CHAR(end_date, 'DD-MON-YYYY') AS end_date  FROM   dba_network_acl_privileges;

		Nice writeup on adding/editing/dropping ACLs:
		
		http://amit7oracledba.blogspot.com/2013/05/ora-24247-network-access-denied-by.html
		
		---------------
		
		If you have permission issues running this procedure:
		
		   grant execute on uis_utils.uis_sendmail to <a_schema>;

		If you're attempting to modify this procedure from your own schema, you'll need:
		
		   grant create any procedure to vhube3adm;


Author:	Vern Huber

Enhancements:
		___ Support for Attachments:  [/home/its_services/data/oraprod] exist on both OraProd and GPLProd to
		share files (e.g., for sending attachments.
		
		Consider converting to [ UTL_MAIL ] for better support of attachments, but you only get 1 attachment.
		
		...or

		Make use of SMTP attachment capability, see the following URLs:
		
		https://www.experts-exchange.com/articles/7749/How-to-Send-Email-Attachments-with-Oracle.html
		https://akdora.wordpress.com/2009/08/13/sending-mail-with-clob-attachment/
		
		...but we will need to split on file separator (for multiple files), and read file in
		and skip over errant files.
		
		Consider using:  uis_utils.file_utils.basename() to get base name of file.
		
		
Usage:	For general campus wide emails:
		exec uis_utils.uis_sendmail.send_html( to_list => 'vhube3@uis.edu', subject => 'Hello Subject', body_of_msg => 'Just some test data!' )
    		
		For ITS Mtce emails (to campus):
		exec uis_utils.uis_sendmail.send_html( to_list => 'vhube3@uis.edu', subject => 'ITS Mtce Subject', body_of_msg => 'ITS is needing you to...', group_id => 11 ) 
		
		...if [test_only] is set to anything other than 'N', the email is sent to a fake SMTP server and does not go out.
		...currently this is the Docker MailHog server.
*/
CREATE OR REPLACE PACKAGE uis_utils.uis_sendmail  as

    TYPE T_ARRAY IS TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER; 
	CRLF CONSTANT VARCHAR2(2 CHAR) := chr(13)||chr(10);
	  
	FUNCTION	split (in_string VARCHAR2, delimiter VARCHAR2) RETURN t_array;

	FUNCTION	removeDuplicates (group1 t_array) return t_array;

	FUNCTION	parseRecipients( recipient CLOB, to_hdr CLOB, cc_hdr CLOB ) return t_array;

	PROCEDURE	send_plain(recipient LONG, from_hdr LONG, to_hdr LONG, cc_hdr LONG, subject LONG, text LONG);

	PROCEDURE	send_html( sent_by CLOB  default '',  to_list CLOB,  cc_list CLOB default '',  subject CLOB,  body_of_msg CLOB,  group_id  NUMBER  default 10,  test_only VARCHAR2 default 'N');

END ;
/


create or replace PACKAGE BODY  uis_utils.uis_sendmail  
as
FUNCTION split (in_string VARCHAR2, delimiter VARCHAR2) RETURN t_array 
IS 
	i       	NUMBER :=0; 
	position 	NUMBER :=0; 
	inputList 	varchar2(1000) := in_string; 
	tableOfStrings 	t_array; 
BEGIN 
	-- Validate the String - It must end w/ a delimiter
	IF substr(inputList, length(inputList) - 1, length(inputList)) <> delimiter
	THEN
		inputList := inputList || delimiter; 
	end if;

	position := instr(inputList, delimiter, 1, 1); 
	WHILE ( position <> 0) LOOP 
		i := i + 1; 
		tableOfStrings(i) := substr(inputList, 1, position - 1); 
		inputList := substr(inputList, position + 1, length(inputList)); 
		position := instr(inputList, delimiter, 1, 1); 
		IF position = 0 THEN 
			tableOfStrings(i + 1) := inputList; 
		END IF; 
	END LOOP; 

	RETURN tableOfStrings; 
END split;
			
FUNCTION removeDuplicates (group1 t_array) return t_array
IS
   	group2	t_array;
   	x 		PLS_Integer;
   	y 		PLS_Integer;
  	alreadyCopied	BOOLEAN;
BEGIN

	x := group1.FIRST;
	group2 (1) := group1 (1);

	LOOP
	   ALREADYCOPIED := FALSE;
	   EXIT WHEN X IS NULL;

	   Y := group2.FIRST;
	   LOOP
		EXIT WHEN Y IS NULL;

		IF group1(X) = group2(Y) THEN
			ALREADYCOPIED := TRUE;
		END IF;

		Y := group2.NEXT(Y);
	   END LOOP;
	   -- end of loop on Y

	   IF NOT ALREADYCOPIED THEN
		group2(X) := group1(X);
	   END IF;   			

	   X := group1.next(x);

	END LOOP;
	-- end of loop on X

	RETURN group2;   
END removeDuplicates;
			   
FUNCTION parseRecipients( recipient CLOB, to_hdr CLOB, cc_hdr CLOB ) return t_array
IS
    arrRecipients 		t_array;
	lstRecipients		long	:= '';
	arrIndx		   		PLS_INTEGER 	:= 0;
BEGIN

	if ( recipient is NULL or recipient = '' ) then
		arrRecipients := SPLIT('', ';');
		return arrRecipients;
	end if;
	lstRecipients := recipient ;

	if ( to_hdr != NULL  and  to_hdr != '' ) then
		lstRecipients := lstRecipients || ';' || to_hdr ;
	end if;
	if ( cc_hdr != NULL  and  cc_hdr != '' ) then
		lstRecipients := lstRecipients || ';' || cc_hdr ;
	end if;

	-- split it into an array
	arrRecipients := SPLIT(lstRecipients, ';');

	-- Remove duplicates 
        arrRecipients := REMOVEDUPLICATES(arrRecipients);
	
       RETURN arrRecipients ;

END parseRecipients;

-- Pass in ';' delimited list of email addresses
--
PROCEDURE send_plain(recipient LONG, from_hdr LONG, to_hdr LONG, cc_hdr LONG, subject LONG, text LONG)
IS
	R	LONG := RECIPIENT;
	F	LONG := FROM_HDR;
	T	LONG := TO_HDR;
	CC	LONG := CC_HDR;
	S 	LONG := SUBJECT;
	TX	LONG := TEXT;
	mail_conn	UTL_SMTP.CONNECTION;
	MSG	LONG;
	RECIPIENTS	T_ARRAY;
	V_ROW	PLS_INTEGER;
BEGIN

/* Using 10g MAIL utility was garbling the subject on into the text body...

	UTL_MAIL.SEND ( sender =>F, recipients =>R, cc =>CC, bcc =>NULL,
		subject =>S, message =>TX, 
		mime_type => 'text/plain;',
		priority => 1
	) ;
--		mime_type => 'text/plain; charset=us-ascii',
*/
/* Revert back to using old UTL_SMTP pkg... */

	-- the list of recipients is what determines who really gets this email
	--
	if CC != '' then
		R := R || ';' || CC;
	end if;

	RECIPIENTS := SPLIT(R, ';');
	RECIPIENTS := REMOVEDUPLICATES(RECIPIENTS);
				
	MSG := 'Date: ' || 
        	TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' ) || crlf ||
           	'From: <'|| F ||'>' || crlf ||
           	'Subject: '|| S || crlf ||
           	'To: '|| T || crlf || 
           	'Cc: '|| CC || crlf || '' || crlf || TX;
				
	V_ROW := RECIPIENTS.FIRST;
	LOOP
		EXIT WHEN v_row IS NULL;
      		IF recipients(v_row) IS NOT NULL
      		THEN
	      		mail_conn := utl_smtp.open_connection('localhost', 25);
			utl_smtp.HELO(mail_conn,'localhost');
			utl_smtp.mail(mail_conn, F);
			utl_smtp.rcpt(mail_conn, recipients(v_row));
			utl_smtp.data(mail_conn, MSG);
			utl_smtp.quit(mail_conn);
		END IF;

		v_row := recipients.NEXT (v_row);
	END LOOP;
-- */

END send_plain;

-- Chunk the msg to get around the varchar data limit.
--
-- PROCEDURE SEND_HTML_CLOB( sent_by CLOB, to_list CLOB, 
--
PROCEDURE send_html( sent_by  CLOB  default '',  to_list  CLOB,  cc_list  CLOB default '',  subject  CLOB,  body_of_msg  CLOB
	, group_id  NUMBER  default 10 , test_only VARCHAR2 default 'N'
)
IS
    conn 		UTL_SMTP.CONNECTION;
    SMTP_SERVER     VARCHAR2(100);	-- eg, smtp.uis.edu, vs uisdocker3.uisad.uis.edu
	SMTP_PORT		NUMBER ;		-- eg, 25 vs 1025 (respectively for server eg above)
	TO_HDR		CLOB := 'To: ';
	CC_HDR		CLOB := 'CC: ';
	SENT_FROM 	CLOB := '';
    R_ARRAY      T_ARRAY;
    indx   		PLS_INTEGER;

    CRLF VARCHAR2( 2 ):= CHR( 13 ) || CHR( 10 );

	HTML_HEAD	CLOB := '';
	HTML_TAIL	CLOB := '';
	PLATFORM	VARCHAR2(100) := '';
	this_instance	VARCHAR2( 1000 ) := '';
	this_subject	LONG := '';
	HTML_BODY	CLOB := '';
	MSG     	CLOB := '';
	MSG_ENCODED     CLOB := '';

	msg_sz		NUMBER := 0;
	chunk_sz	NUMBER := 0;
	msg_idx		NUMBER := 1;

	param_err	VARCHAR2(1) := 'N';
	error_email_msg		VARCHAR(4000) := '';
	error_email_to		VARCHAR(1000) := '';
BEGIN

	select lower( instance_name ) into this_instance from  v$instance;
			
	-- The following logic is used to grab param value the caller has request (if they didn't go with the default)
	-- ...and grabs default if a unique param is not defined for the group for the param they've requested.
	--
	select max( param_value ) keep ( dense_rank  first  order by param_id  desc ) into HTML_HEAD  from (
	   select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = group_id  and  PARAM_CD = 'HTML_HEAD'
	   union 
       select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = 10 and  PARAM_CD = 'HTML_HEAD' 
	) t  group by t.param_cd ;
	if ( HTML_HEAD = '' ) then  param_err := 'Y';  end if;
		
	select max( param_value ) keep ( dense_rank  first  order by param_id  desc ) into HTML_TAIL  from (
	   select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = group_id  and  PARAM_CD = 'HTML_TAIL'
	   union 
       select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = 10 and  PARAM_CD = 'HTML_TAIL' 
	) t  group by t.param_cd ;
	if ( HTML_TAIL = '' ) then  param_err := 'Y';  end if;

	select max( param_value ) keep ( dense_rank  first  order by param_id  desc ) into PLATFORM  from (
	   select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = group_id  and  PARAM_CD = 'PLATFORM_TYPE'
	   union 
       select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = 10 and  PARAM_CD = 'PLATFORM_TYPE' 
	) t  group by t.param_cd ;
	if ( PLATFORM = '' ) then  param_err := 'Y';  end if;		
	
	select max( param_value ) keep ( dense_rank  first  order by param_id  desc ) into SENT_FROM  from (
		select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = group_id  and  PARAM_CD = 'EMAIL_FROM'
		union 
		select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = 10 and  PARAM_CD = 'EMAIL_FROM' 
	) t  group by t.param_cd ;
	if ( SENT_FROM = '' ) then  param_err := 'Y';  end if;	
	
	-- See if we are being called for a test only send - this determines how to configure the SMTP Server and Port.
	--
	if ( test_only != 'N' )
	then
		SMTP_SERVER := 'uisdocker3.uisad.uis.edu';
		SMTP_PORT := 1025;
	else
		select max( param_value ) keep ( dense_rank  first  order by param_id  desc ) into SMTP_SERVER  from (
			select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = group_id  and  PARAM_CD = 'SMTP_SERVER'
			union 
			select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = 10 and  PARAM_CD = 'SMTP_SERVER' 
		) t  group by t.param_cd ;
		if ( SMTP_SERVER = '' ) then  param_err := 'Y';  end if;	
	
		select max( to_number( param_value ) ) keep ( dense_rank  first  order by param_id  desc ) into SMTP_PORT  from (
			select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = group_id  and  PARAM_CD = 'SMTP_PORT'
			union 
			select  param_value, param_id, param_cd  from uis_utils.UIS_SYS_PARAM_LKP  where param_id = 10 and  PARAM_CD = 'SMTP_PORT' 
		) t  group by t.param_cd ;
		if ( SMTP_PORT = '' ) then  param_err := 'Y';  end if;
		
	end if;		-- ...test_only mode (to set SMTP server accordingly).
		
	-- If the caller passed in an account they wish to send this email as, override what we currently have now.
	--
	if ( sent_by != '' or sent_by is not NULL )
	then
		SENT_FROM := SENT_BY;
	end if;
	

	-- Append the group we are working with as a debugging aid.
	HTML_TAIL := HTML_TAIL || '<style> font.its_tail { color:grey;font-size:7pt; } </style><font class="its_tail">(appId = '|| group_id ||' ) ';
	 
	-- </font> was print out the partial end tag so I just removed it.
	HTML_BODY := HTML_HEAD || body_of_msg || HTML_TAIL ;


    -- CONFIGURE SENDING MESSAGE
    -- You need to put 'MIME-Verion: 1.0' (this is case-sensitive!)
    -- Content-Type-Encoding is actually Content-Transfer-Encoding.
    -- The MIME-Version, Content-Type, Content-Transfer-Encoding should
    -- be the first 3 data items in your message
	--
	
	/* OPEN CONNECTION */
	conn:= utl_smtp.open_connection( SMTP_SERVER, SMTP_PORT );

	/* HAND SHAKE */
    utl_smtp.helo( conn, SMTP_SERVER );

	/* CONFIGURE SENDER */
    utl_smtp.mail( conn, SENT_FROM );		-- was using utl_smtp.mail( conn, SENT_BY ); ...but some serves require a value

	/* CONFIGURE RECIPIENT: TO-list */
	R_ARRAY := parseRecipients( to_list, '', ''); 
    indx := R_ARRAY.FIRST;
    loop
        EXIT WHEN indx IS NULL;
        if R_ARRAY(indx) IS NOT NULL
        then
			utl_smtp.rcpt( conn, R_ARRAY(indx) );
			TO_HDR := TO_HDR || R_ARRAY(indx) ||'; ';
        end if;

        indx := R_ARRAY.NEXT(indx);
    end loop;
 
	/* CONFIGURE RECIPIENT: CC-list (may be empty) */
	R_ARRAY := parseRecipients( cc_list, '', ''); 
    indx := R_ARRAY.FIRST;
    loop
		EXIT WHEN indx IS NULL;
        if R_ARRAY(indx) IS NOT NULL
        then
			utl_smtp.rcpt( conn, R_ARRAY(indx) );
			CC_HDR := CC_HDR || R_ARRAY(indx) ||'; ';
		end if;

        indx := R_ARRAY.NEXT(indx);
    end loop;

	
	-- ENCODE using base64 (ratio 3:4 (3bytes in/ 4bytes out)) - so use a chunk size that returns 2k.
	--
	chunk_sz := 1536;
	msg_idx	 := 1;
	select length( HTML_BODY ) into msg_sz  from DUAL;
	LOOP
		EXIT WHEN msg_idx > msg_sz;

		MSG_ENCODED := MSG_ENCODED || UTL_ENCODE.TEXT_ENCODE( 
			substr( HTML_BODY, msg_idx, chunk_sz ), NULL, UTL_ENCODE.BASE64);
		msg_idx := msg_idx + chunk_sz ;

	END LOOP;
	
	if PLATFORM != 'PRODUCTION'
	then
		this_subject :=  '['|| this_instance ||'] ';
	end if;
	
	if group_id = 12	-- preface subject for exception case calls...
	then
	   this_subject :=  ''|| this_subject ||' EXCEPTION: ';
	end if;
	
	this_subject := this_subject || SUBJECT;

    -- MSG := 'Date: '||TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' )||CRLF||
    MSG := 'Date: '|| to_char( SYSTIMESTAMP AT TIME ZONE 'America/Chicago', 'Dy, DD Mon RRRR HH24:MI:SS TZHTZM', 'NLS_DATE_LANGUAGE=AMERICAN') ||	
         'From:'|| SENT_FROM ||CRLF||
         'Subject: ' || this_subject ||CRLF|| TO_HDR ||CRLF|| CC_HDR ||CRLF||
         '' || crlf || MSG_ENCODED ||'';
		 
	utl_smtp.open_data( conn );
	utl_smtp.write_data(conn,
		'MIME-Version: 1.0' ||CHR(13)|| CHR(10)||
		'Content-type: text/html;' ||CHR(13)|| CHR(10)||
		'Content-transfer-encoding: base64' || CHR(13)||CHR(10) );

	-- Now append the msg - in chunks of 2k...
	chunk_sz := 2048;
	msg_idx	 := 1;
	select length( MSG ) into msg_sz  from DUAL;
	LOOP
		EXIT WHEN msg_idx > msg_sz;

        	utl_smtp.write_data( conn, substr( MSG, msg_idx, chunk_sz ) );

		msg_idx := msg_idx + chunk_sz ;

	END LOOP;

	utl_smtp.close_data( conn );

	-- IF an error occurred retrieving a parameter, report it now.
	if ( param_err = 'Y' )
    then

		select max( param_value ) keep ( dense_rank  first  order by param_id  desc ) into error_email_msg  from (
			select  param_value, param_id, param_cd  from uis_utils.uis_SYS_PARAM_LKP  where param_id = group_id  and  PARAM_CD = 'ERROR_EMAIL_MSG'
			union 
			select  param_value, param_id, param_cd  from uis_utils.uis_SYS_PARAM_LKP  where param_id = 10 and  PARAM_CD = 'ERROR_EMAIL_MSG' 
		) t  group by t.param_cd ;
		
		select max( param_value ) keep ( dense_rank  first  order by param_id  desc ) into error_email_to  from (
			select  param_value, param_id, param_cd  from uis_utils.uis_SYS_PARAM_LKP  where param_id = group_id  and  PARAM_CD = 'ERROR_EMAIL_TO'
			union 
			select  param_value, param_id, param_cd  from uis_utils.uis_SYS_PARAM_LKP  where param_id = 10 and  PARAM_CD = 'ERROR_EMAIL_TO' 
		) t  group by t.param_cd ;

		R_ARRAY := parseRecipients( error_email_to, '', ''); 
        indx := R_ARRAY.FIRST;
		TO_HDR := 'To: ';
        LOOP
            EXIT WHEN indx IS NULL;
            IF R_ARRAY(indx) IS NOT NULL          
			THEN
		        utl_smtp.rcpt( conn, R_ARRAY(indx) );
				TO_HDR := TO_HDR || R_ARRAY(indx) ||'; ';
            END IF;
            indx := R_ARRAY.NEXT(indx);
        END LOOP;

		this_subject := '[ '|| this_instance ||' ALERT: uis_utils.UIS_SYS_PARAM_LKP ] parameters missing in DB';
		
		HTML_BODY := 'The DB utility [uis_utils.uis_sendmail] has discovered that one or more of the following parameters'
			||CHR(13)|| CHR(10) ||' { EMAIL_FROM, ERROR_EMAIL_MSG, ERROR_EMAIL_TO, HTML_HEAD, HTML_TAIL } '
			||CHR(13)|| CHR(10) ||'are/is missing in [uis_utils.uis_SYS_PARAM_LKP] in the DB '	
			|| this_instance ||' ('|| sysdate ||')<br/><br/>' 
			||CHR(13)|| CHR(10) ||'Remember to populate entries for: EMAIL_FROM,  ERROR_EMAIL_MSG,  ERROR_EMAIL_TO, HTML_HEAD, HTML_TAIL';

		-- ENCODE using base64 (ratio 3:4 (3bytes in/ 4bytes out)) - so use a chunk size that returns 2k.
		--
		chunk_sz := 1536;
		msg_idx	 := 1;
		MSG_ENCODED := '';
		select length( HTML_BODY ) into msg_sz  from DUAL;
		LOOP
			EXIT WHEN msg_idx > msg_sz;

			MSG_ENCODED := MSG_ENCODED || UTL_ENCODE.TEXT_ENCODE( substr( HTML_BODY, msg_idx, chunk_sz ), NULL, UTL_ENCODE.BASE64 );
			msg_idx := msg_idx + chunk_sz ;
		END LOOP;
	
		-- MSG := 'Date: '|| to_char( SYSDATE, 'dd Mon yy hh24:mi:ss' )||CRLF||  ...started causing a 5hr diff (UTC vs UTC-5/CST).
		MSG := 'Date: ' || to_char( SYSTIMESTAMP AT TIME ZONE 'America/Chicago', 'Dy, DD Mon RRRR HH24:MI:SS TZHTZM', 'NLS_DATE_LANGUAGE=AMERICAN') ||CRLF||	
         'From:'|| error_email_to ||CRLF||
         'Subject: ' || this_subject ||CRLF|| TO_HDR || CRLF ||
         '' || crlf || MSG_ENCODED ||'';

        -- CONFIGURE SENDING MESSAGE
		--
		utl_smtp.open_data( conn );
		utl_smtp.write_data(conn,  'MIME-Version: 1.0' ||CHR(13)|| CHR(10)||'Content-type: text/html;' ||CHR(13)|| CHR(10)||'Content-transfer-encoding: base64' || CHR(13)||CHR(10) );

		-- Now append the msg - in chunks of 2k...
		chunk_sz := 2048;
		msg_idx	 := 1;
		select length( MSG ) into msg_sz  from DUAL;
		LOOP
			EXIT WHEN msg_idx > msg_sz;

        	utl_smtp.write_data( conn, substr( MSG, msg_idx, chunk_sz ) );

			msg_idx := msg_idx + chunk_sz ;

		END LOOP;

		utl_smtp.close_data( conn );

	end if;
	-- End of check for parameter lookup failure ...and reporting on it.
	
    /* Closing Connection */
    utl_smtp.quit( conn );

    EXCEPTION when OTHERS then
	utl_smtp.quit( conn );
	raise;

END send_html;

-- END of PKG uis_utils.uis_sendmail

END ;

