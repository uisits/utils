/*
File:	utils/oracle/uis_lob.pkb

Desc:	Package for custom utilities for working with LOB/CLOB/BLOBs.

		Initial need was for outputing CLOB content in a SQLPLUS session which has a
		size limitaion.
		
		!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		
		This UTILITY SHOULD BE APPLIED on each Oracle instance server;
		
		!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	
Note:	If you have permission issues running this procedure:
		
		grant execute on  uis_utils.uis_lob to public;
		
		To use [write_clob2file], the following needs to be done:
		--
		create or replace directory TMP_DIR as '/home/oracle/tmp';	
		...Oracle uses upper internally, and this dir must exist on DB server
		
		grant read, write on directory TMP_DIR to  public -- uis_utils;
		GRANT EXECUTE ON SYS.utl_file TO uis_utils;  -- as SYS
		
		...and some testing items:
		--
		exec uis_utils.uis_lob.write_clob2file( 'hello world', 'howdy' );  -- test

		SELECT name   FROM V$PARAMETER  WHERE upper( NAME ) = 'UTL_FILE_DIR';
		SELECT * FROM all_tab_privs WHERE grantee = 'PUBLIC' AND table_name = 'UTL_FILE';
		
		!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		
		DBBM_XSLPROCESSOR.clob2file() performs a similar function as [write_clob2file],
		but it will not follow symbolic links on the DB server (UTL_FILE will).
		
	    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Author:	Vern Huber - June 5, 1963

Enhancements:
		___ ???;

Usage:	For writing output of a session - and get around the per output size restriction
		of 2k for sqlplus (but there is still an issue being seen in the first couple of lines
		where a character is dropped):
		
		
		
		For writing CLOBs to a file:
		

*/
CREATE OR REPLACE PACKAGE uis_utils.UIS_LOB  as

	-- Use put_line() to chunk up a CLOB and print it out (issues at printing the 51st char)...
	procedure  print_clob( clob_2_prt in CLOB ) ;

	-- Write a CLOB passed in to a file (passed in)...
    procedure write_clob2file( clob_2_wrt in CLOB,  fname in varchar2,  charset in varchar2  default 'AL32UTF8' );

END ;

grant execute on  uis_utils.uis_lob to public;


CREATE OR REPLACE PACKAGE BODY uis_utils.UIS_LOB  as

procedure print_clob( clob_2_prt in CLOB )
as
   l_offset 		number	default 1;
   chunk_threshold 	number	default 255;
   chunk_sz			number;	-- Amount of chars to be printed

   eol_amt		number;		-- Number of chars to EOL
   whsp_amt		number;		-- " " " to Whitespace
   clob_len		number;
begin
   clob_len := dbms_lob.getlength( clob_2_prt );

   loop
      exit when l_offset > clob_len;
	  
      -- Grab a chunk of data - up to the EOL, but stay around the [chunk_threshold]
	  --
      select instr( clob_2_prt, chr(10), l_offset, 1 ) into eol_amt  from DUAL ;   
	  
	  chunk_sz := chunk_threshold;
	  
	  if eol_amt > chunk_threshold  or eol_amt = 0
      then
	 
         -- Dealing with a long line, use whitespace/blank as delimiter (1st from end of desired chunk size)
	     select instr( dbms_lob.substr( clob_2_prt, chunk_threshold, l_offset ), ' ', -1, 1 ) into whsp_amt  from DUAL ;   
		 
		 if whsp_amt > 0
		 then
		    chunk_sz := whsp_amt ;
		 end if;
		 
         dbms_output.put_line( dbms_lob.substr( clob_2_prt, chunk_sz, l_offset ) );

	  else
	     chunk_sz := eol_amt ; 
		 
		 -- put_line() will add its own CHR(10), so leave 1 off...
		 dbms_output.put_line( dbms_lob.substr( clob_2_prt, chunk_sz -1, l_offset ) );

	  end if;
	  
      l_offset := l_offset + chunk_sz;
	  
   end loop;
   
end print_clob;

-- REQUIRES: create or replace directory TMP_DIR as '/tmp';  -- Oracle uses upper case internally
--
procedure write_clob2file( clob_2_wrt in CLOB,  fname in varchar2,  charset in varchar2  default 'AL32UTF8' )
as
   l_offset 	number	default 1;
   chunk_sz 	number	default 3600;  -- 32767;
   rem_chunk_sz	number	default 3600;  -- 32767;	-- remaining chunk size (for when we are near the end of the CLOB - to prevent EOF err for UTL_FILE)
   clob_len		number;
   -- chunk_2_wrt	CLOB;
   chunk_2_wrt	varchar2( 4000 char );
   f_handle		UTL_FILE.FILE_TYPE;
   
begin
   f_handle := UTL_FILE.FOPEN('TMP_DIR', fname, 'w');
   clob_len := dbms_lob.getlength( clob_2_wrt );

   loop
      exit when l_offset > clob_len;
	  
	  -- chunk_2_wrt := dbms_lob.substr( clob_2_wrt, chunk_sz, l_offset );
	  chunk_2_wrt := convert( dbms_lob.substr( clob_2_wrt, chunk_sz, l_offset ), 'AL32UTF8') ;

	  rem_chunk_sz := dbms_lob.getlength( chunk_2_wrt );

	  if rem_chunk_sz < chunk_sz
	  then
	     chunk_sz := rem_chunk_sz;
	  end if;
	  
	  UTL_FILE.put( f_handle, chunk_2_wrt );

	  UTL_FILE.fflush( f_handle );
	   
	  l_offset := l_offset + chunk_sz;

   end loop; 
   
   -- DBMS_OUTPUT.PUT_LINE('...l_offset = ' || l_offset || '  chunk_sz = ' || chunk_sz );

   UTL_FILE.fclose( f_handle );

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Exception: SQLCODE=' || SQLCODE || '  SQLERRM=' || SQLERRM);
      UTL_FILE.fclose( f_handle );
   
end write_clob2file;

-- END of PKG uis_utils.UIS_LOB
END ;

