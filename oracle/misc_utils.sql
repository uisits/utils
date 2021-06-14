/* 
File:	utils/oracle/misc_utils.sql 
 
Desc:	Oracle utilities commonly needed across applications;
		
Utilities:	
		term_to_semester( term_cd )
		semester_to_term( semester ) 
		is_online_crs( sched_type_cd )  ==> true, false
		get_sched_method( sched_type_cd )
		get_sess_method( sess_cd )
		is_number( <string in> )
		get_number( <string_in> )
		replace_abbrv()
		replace_abbrv_all()
		smartcap()
		fmt_phone_nbr()
		
See:	
	
Author:	Vern Huber - Feb. 22, 2019  

Enhancements:
		TBD
		
*/
-- FMT_PHONE_NBR: accepts a phone number formatted or not, and formats it in:
-- ...fmt_style = 'classic' (default):	xxx xxx-xxxx  or xxx-xxxx (a)
-- ...fmt_style = 'formal':				(xxx) xxx-xxxx  or xxx-xxxx (a)
-- ...fmt_style = 'internet':			xxx.xxx.xxxx  or xxx.xxxx (a)
-- ...fmt_style = 'raw' or any other value than { classic, formal, internet }:	Unformatted number (no whitespace)
--
-- (a) If a 7 digit value is passed in, after removing non-numeric digts (i.e, formatting).
--
-- E.g.:   select   uis_utils.term_to_semester( '420195' )  as sem   from dual;
--
create or replace function  uis_utils.fmt_phone_nbr( 
   ph_nbr  			in varchar2
   , fmt_style		in varchar2		default 'classic'
)  return VARCHAR2  
is
   fmt_ph_nbr		varchar2( 20 ); 
   nbr				varchar2( 100 ); 
BEGIN 
   -- Remove any current formatting...
   nbr :=  regexp_replace( ph_nbr, '[[:alpha:][:punct:][:space:]]' );

   fmt_ph_nbr := case 
      when fmt_style = 'classic'  and length( nbr ) = 10	then substr( nbr, 1,3 ) ||' '|| substr( nbr, 4,3 ) ||'-'|| substr( nbr, 7,4 )
      when fmt_style = 'classic'  and length( nbr ) = 7	then substr( nbr, 1,3 ) ||'-'|| substr( nbr, 4,4 )
      when fmt_style = 'formal'  and length( nbr ) = 10	then '('|| substr( nbr, 1,3 ) ||') '|| substr( nbr, 4,3 ) ||'-'|| substr( nbr, 7,4 )
      when fmt_style = 'formal'  and length( nbr ) = 7	then substr( nbr, 1,3 ) ||'-'|| substr( nbr, 4,4 )
      when fmt_style = 'internet' and length( nbr ) = 10	then substr( nbr, 1,3 ) ||'.'|| substr( nbr, 4,3 ) ||'.'|| substr( nbr, 7,4 )
      when fmt_style = 'internet'  and length( nbr ) = 7	then substr( nbr, 1,3 ) ||'.'|| substr( nbr, 4,4 )
      when length( nbr ) > 20	then 'Invalid Phone #'
      else nbr
   end;
    
  return fmt_ph_nbr; 
  
END;	-- of fmt_phone_nbr()
--
grant execute on uis_utils.fmt_phone_nbr  to public;

-- TERM_TO_SEMESTER: pass in a term_cd (6 digits) and get back a semester (5 ditits)
-- ...420198 --> 20193  (1: Spring;  2: Summer;  3: Fall;)
-- ...BB uses this format at times.
--
-- E.g.:   select   uis_utils.term_to_semester( '420195' )  as sem   from dual;
--
create or replace FUNCTION  uis_utils.term_to_semester( term_cd  IN VARCHAR2 ) 
   return VARCHAR2  AS semester  VARCHAR2( 5 ); 
BEGIN 
   semester := case 
      when substr( term_cd, 6,1 ) = '1'  then  substr( term_cd, 2,4 ) ||'1' 
  	  when substr( term_cd, 6,1 ) = '5'  then  substr( term_cd, 2,4 ) ||'2'
	  else  substr( term_cd, 2,4 ) ||'3'
   end;
    
  return semester; 
END;
--
grant execute on uis_utils.term_to_semester  to public;
				
-- SEMESTER_TO_TERM: pass in a semester (5 ditits) and get back a term_cd (6 digits)
-- ...20193 --> 420198  (1: Spring;  5: Summer;  8: Fall;)
--
-- E.g.:   select   uis_utils.semester_to_term( '20192' )  as term_cd   from dual;
--
create or replace FUNCTION  uis_utils.semester_to_term( semester  IN VARCHAR2 ) 
   return VARCHAR2  AS term_cd  VARCHAR2( 6 ); 
BEGIN 

   term_cd  := case   
      when ( substr( semester,5,1 ) = '2') then '4'|| substr( semester,1,4 )||'5'
      when ( substr( semester,5,1 ) = '3') then '4'|| substr( semester,1,4 )||'8' 
      else '4'|| semester    
   end;
  
  return term_cd; 
END;
--
grant execute on uis_utils.semester_to_term  to public;

			
-- IS_ONLINE_CRS: pass in a [SCHED_TYPE_CD](3 chars) and get back { true, false } literals
-- ...retrieved from (commonly): T_Sect_Base.sched_type_cd - and there are over 40 of them;
--
-- E.g.: select uis_utils.is_online_crs( 'ONL' ) from dual;
--
create or replace FUNCTION  uis_utils.is_online_crs( sched_type_cd  IN VARCHAR2 ) 
   return VARCHAR2  AS online_flag  VARCHAR2( 5 ); 
BEGIN 

   online_flag  := case   
      when (substr( sched_type_cd, 1, 1) = 'E')   then 'true'
	  when ( sched_type_cd = 'ONL')               then 'true'
      else 'false'
   end;
  
  return online_flag; 
END;
--
grant execute on uis_utils.is_online_crs  to public;
    
			
-- GET_SCHED_METHOD: pass in a [SCHED_TYPE_CD](3 chars) and get back { ONLINE, ONGROUND } literals
-- ...retrieved from (commonly): T_Sect_Base.sched_type_cd - and there are over 40 of them;
--
-- Course Evaluations was initial user of this scheme - maybe the only one, and was checking for sched_type_cd:
--    Online <== ONL,E8,E9,E7,E1,E5,E4,E3,E2,E6
--    Onground <== CLP,STA,DIS,N1,IND,N2,N3,N4,LAB,LBD,L1,LEC,S4,S5,S1,S2,S3,LCD,CNF,ST,Q,P2,P3,PR,P1,PKG
--
-- See: uis_utils.is_onlince_crs();
-- 		edw.T_SCHED_TYPE_CD
--
-- E.g.: select uis_utils.is_online_crs( 'ONL' ) from dual;
--
create or replace FUNCTION  uis_utils.get_sched_method( sched_type_cd  IN VARCHAR2 ) 
   return VARCHAR2  AS r_sched_method  VARCHAR2( 10 ); 
BEGIN 

   r_sched_method  := case   
      when (substr( sched_type_cd, 1, 1) = 'E')   then 'ONLINE'
	  when ( sched_type_cd = 'ONL')               then 'ONLINE'
      else 'ONGROUND'
   end;
  
  return r_sched_method; 
END;
--
grant execute on uis_utils.get_sched_method  to public;
    

			
-- GET_SESS_METHOD: pass in a [SCHED_TYPE_CD](3 chars) and get back { ONLINE, MIXED } literals
-- ...retrieved from (commonly): T_Sect_Base.sched_type_cd - and there are over 40 of them;
--
-- Course Evaluations was initial user of this scheme - maybe the only one, and was checking for SESS_CD:
--    Online <== O
--    Onground <== B,C,V,L,I
--
-- See: uis_utils.is_onlince_crs();
--		edw.T_SESS_CD
--
-- E.g.: select uis_utils.is_online_crs( 'ONL' ) from dual;
--
create or replace FUNCTION  uis_utils.get_sess_method( sess_cd  IN VARCHAR2 ) 
   return VARCHAR2  AS r_sess_method  VARCHAR2( 10 ); 
BEGIN 

   r_sess_method  := 'MIXED';
   
   if ( sess_cd = 'O' )
   then  
		r_sess_method := 'ONLINE';
   end if;
  
  return r_sess_method; 
END;
--
grant execute on uis_utils.get_sess_method  to public;


			
-- IS_NUMBER: Check if string is numeric.
-- ...returns {0} : if string is not numeric;
-- ...returns {1} : if number - as determined by [ to_number ];
--
-- E.g.: case when uis_utils.is_number( '21345.56' ) = 1  then ... else ... end;
--
create or replace function  uis_utils.IS_NUMBER( str_nbr	in varchar2 )
  RETURN INT
IS
  is_nbr	NUMBER;
BEGIN
   is_nbr := to_number(str_nbr);
   return 1;
  
EXCEPTION
   WHEN VALUE_ERROR THEN
   return 0;
   
END; 	-- uis_utils.IS_NUMBER;
--
grant execute on uis_utils.IS_NUMBER  to public;

   
-- GET_NUMBER: Accepts a string as input and returns a numeric as the result.
-- ...returns {0} if string is not numeric;
-- ...returns [to_number( str )] otherwise;
--
-- NOTE: Simple formatting is removed: commas and dollar sign ($)
--
-- E.g.: select uis_utils.get_number( '21345.56' ) from dual;
-- ...or select uis_utils.get_number( '$1,234.56' ) from dual;
-- 

create or replace function  uis_utils.GET_NUMBER( 
   str_nbr		in VARCHAR2
   , fmt		in VARCHAR2		default NULL
)  return NUMBER
is 
  r_number 			NUMBER := 0;
  str_nbr_prep		VARCHAR2( 1000 );

BEGIN  
   -- strip out commas and dollar sign ($)...
   str_nbr_prep := replace( replace( str_nbr, ',', NULL ), '$', NULL );

   if ( uis_utils.is_number( str_nbr_prep) = 0 )
   then
      return r_number;
   end if; 
	     
   if ( fmt is null )
   then  
		r_number := to_number( str_nbr_prep );
   else 
		r_number := to_number( str_nbr_prep, fmt );
   end if;
  
  return r_number; 
  
END ;		-- uis_utils.GET_NUMBER;
--
grant execute on uis_utils.GET_NUMBER  to public;

/*
-- REPLACE_ABBRV: Act on an item for replacements based upoin flags passed in.

keep_acronym_flag - Looks for entry in the SMARTCAP table, and uses it for the replacement.
...otherwise the ABBREVIATIONS table is used.

initcap_flag - If no replacement value is found (either SMARTCAP or ABBREVIATIONS) based upon
	the request, an initcap() is performed.  Most like used in structured settings - e.g., Titles.

use_acronym_set : for Banner Titles (default: 'BANNER') or for Campus Announcements ('ANNOUNCEMENTS')
	...guides which replacement set is used.
	
If no substitutions were made, returns the exact same term passed in - depending on request.
...e.g., if [initcap_flag=Y], then that utility will be ran.

See:	SMARTCAP() - parses through a string passing each item to this utility.

*/
create or replace function  uis_utils.REPLACE_ABBRV( 
   str_to_acton			in varchar2
   , initcap_flag		in varchar2		default 'Y'
   , keep_acronym_flag	in varchar2		default 'Y'
   , use_acronym_set	in varchar2		default 'BANNER'
)  return VARCHAR2
is 
  str_acted_on		VARCHAR2( 250 );

BEGIN  
   
   -- str_acted_on := str_to_acton ;	-- Default to what was passed in, for case nothing found.
   str_acted_on := NULL;

   if ( keep_acronym_flag = 'Y' )
   then
      select max( ret_value ) into str_acted_on  from team.SMARTCAP  where upper( term ) = upper( str_to_acton ) and is_active = 'Y' and dir_display_flag = 'Y' ;
   end if;
   
   if ( str_acted_on is NULL ) 
   then 
      if ( use_acronym_set	= 'BANNER' ) 
      then
         select max( phrase ) into str_acted_on  from team.ABBREVIATIONS where upper( acronym ) = upper( str_to_acton ) and is_abbrv_banner = 'Y' ;
	  
      else		-- Punt and use Campus Announcements...
         select max( phrase ) into str_acted_on  from team.ABBREVIATIONS where upper( acronym ) = upper( str_to_acton ) and is_abbrv_announcements = 'Y' ;

      end if; 
	  
	  if ( str_acted_on is NULL )  -- ...still nothing has been found, initcap() it.
	  then
	     str_acted_on := initcap( str_to_acton );
	  end if;
   end if;
   
   return str_acted_on; 
  
EXCEPTION

   WHEN OTHERS THEN	return  str_acted_on;
   
END ;		-- uis_utils.REPLACE_ABBRV;
--
grant execute on uis_utils.REPLACE_ABBRV  to public;

/* SMARTCAP: Parse a string for replacements based upoin flags passed in.

First string is split by comma, and then by spaces to get at each word.

Splitting on periods requires too much context - were we at the end of the sentince, was MR. => Mister, ...
...so skip for now - until it's absolutely wanted.   

Note;	MAX string size passed in should be 4000, or less;
		Hyphens are not considered a separator (some acronyms use hyphens);
		New lines and chariage reurns are not handled (yet);
*/
-- drop function  uis_utils.REPLACE_ABBRV_ALL;
--
create or replace function  uis_utils.SMARTCAP( 
   str_to_acton			in VARCHAR2
   , initcap_flag		in varchar2		default 'Y'
   , keep_acronym_flag	in varchar2		default 'Y'
   , use_acronym_set	in VARCHAR2		default 'BANNER'
)  return VARCHAR2
is 
  str_acted_on		VARCHAR2( 4000 );

BEGIN  
   
   str_acted_on := NULL ;	-- Default to what was passed in, for case nothing found.
   
   -- Split the input on [comma](s) as the delimiter - if they exists...
   --
   for  c  in ( select trim( regexp_substr( str_to_acton, '[^,]+', 1, LEVEL )) l  from dual  CONNECT BY LEVEL <= regexp_count( str_to_acton, ',') +1  )
   loop
      -- dbms_output.put_line( c.l );
	  
      -- Iterate across substring using a [space] as the delimiter...
      --	  
      for  i  in ( select trim( regexp_substr( c.l, '[^ ]+', 1, LEVEL )) l  from dual  CONNECT BY LEVEL <= regexp_count( c.l, ' ') +1  )
      loop
         -- dbms_output.put_line( i.l );
	     str_acted_on := str_acted_on ||' '|| uis_utils.REPLACE_ABBRV( i.l, initcap_flag => initcap_flag, keep_acronym_flag => keep_acronym_flag, use_acronym_set => use_acronym_set );

      end loop;	  
	  
	  -- If string passed does not match the size of the substring, then a comma split was was performed - and the comma needs added back
	  --
	  if ( length( str_to_acton ) != length( c.l ) )
	  then
	     str_acted_on := str_acted_on ||',';
	  end if;

   end loop;	-- string split on commas...
   
   -- As a precaution, remove trailing commas...
   --
   str_acted_on := rtrim( str_acted_on, ',' );

   -- remove leading space added for 1st term, before returning item   
   return ltrim( str_acted_on ); 
  
EXCEPTION

   WHEN OTHERS THEN	return  str_acted_on;
   
END ;		-- uis_utils.SMARTCAP;
--
grant execute on uis_utils.SMARTCAP  to public;

