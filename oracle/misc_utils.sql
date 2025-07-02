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
		smartcap() - iterates across a phrase and calls [replace_abbrv()] on each word.
		fmt_phone_nbr()
		hex_to_blob() - large ascii hex character set (eg image) and return a BLOB
See:	
	
Author:	Vern Huber - Feb. 22, 2019  

Enhancements:
		TBD
		
*/

/*
HEX_TO_BLOB() - accepts ascii hex data that is really long (eg image) and converts it to a BLOB
...which is returned.

*/
create or replace function uis_utils.HEX_TO_BLOB( hex_str_in  in CLOB )
  return BLOB
is
  l_raw  			RAW(32767);			-- Intermediate RAW variable (max size)
  l_blob 			BLOB;				-- BLOB to return
  l_offset			NUMBER := 1;		-- Tracks where in the blob to put the next chunk or converted raw data
  l_chunk_size		NUMBER := 32767/2; 	-- Max hex chars per chunk for RAW
begin
  -- Initialize the BLOB
  dbms_lob.CREATETEMPORARY( l_blob, TRUE, dbms_lob.CALL );

  -- Loop through the CLOB in chunks because RAW has a size limit
  while l_offset <= length( hex_str_in ) loop
  
    l_raw := UTL_RAW.CAST_TO_RAW( substr( hex_str_in, l_offset, l_chunk_size ));
	
    dbms_lob.APPEND( l_blob, l_raw );
	
    l_offset := l_offset + l_chunk_size;
	
  end loop;

  return l_blob;
end;



-- FMT_PHONE_NBR: accepts a phone number formatted or not, and formats it in:
-- ...fmt_style = 'classic' (default):	xxx-xxx-xxxx  or xxx-xxxx (a)
-- ...fmt_style = 'formal':				(xxx) xxx-xxxx  or xxx-xxxx (a)
-- ...fmt_style = 'internet':			xxx.xxx.xxxx  or xxx.xxxx (a)
-- ...fmt_style = 'raw' or any other value than { classic, formal, internet }:	Unformatted number (no whitespace)
-- ...if more than 10 digits (stripped formatting) present, the number is returned as passed in.
--
-- (a) If a 7 digit value is passed in, after removing non-numeric digts (i.e, formatting).
--
--
create or replace function  uis_utils.fmt_phone_nbr( 
   ph_nbr  			in varchar2
   , fmt_style		in varchar2		default 'classic'
)  return VARCHAR2  
is
   fmt_ph_nbr		varchar2( 20 ); 
   nbr				varchar2( 100 ); 
   fmt_delimiter	varchar2( 1 );
BEGIN 
   -- Remove any current formatting...
   nbr :=  regexp_replace( ph_nbr, '[[:alpha:][:punct:][:space:]]' );

   if ( fmt_style = 'internet' )
   then  
		fmt_delimiter := '.';
   else 
		fmt_delimiter := '-';	-- classic or formal
   end if;

   fmt_ph_nbr := case 
      when fmt_style = 'formal'  and length( nbr ) = 10		then '('|| substr( nbr, 1,3 ) ||') '|| substr( nbr, 4,3 ) || fmt_delimiter || substr( nbr, 7,4 )
      when length( nbr ) = 10	then substr( nbr, 1,3 ) || fmt_delimiter || substr( nbr, 4,3 ) || fmt_delimiter || substr( nbr, 7,4 )	  
      when length( nbr ) = 7	then substr( nbr, 1,3 ) || fmt_delimiter || substr( nbr, 4,4 )
	  when length( nbr ) = 5	then 'x'|| nbr
      when length( nbr ) > 20	then 'Invalid Phone #'
      else ph_nbr
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


-- GET_CUR_TERM: return the current term_cd
--
-- E.g.:   select   uis_utils.get_cur_term()  as term_cd   from dual;
--
create or replace FUNCTION  uis_utils.get_cur_term
   return VARCHAR2  AS term_cd  VARCHAR2( 6 ); 
begin  
  select current_term into term_cd from uis_edw.VW_SEMESTER ; 

  return ( term_cd ); 
end;
--
grant execute on uis_utils.get_cur_term  to public;

-- GET_CUR_AY_CD: return the current academic year code
--
-- E.g.:   select   uis_utils.get_cur_ay_cd()  as cur_ay_cd   from dual;
--
create or replace FUNCTION  uis_utils.get_cur_ay_cd
   return VARCHAR2  AS ay_cd  VARCHAR2( 4 ); 
begin  
  select academic_yr_cd into ay_cd from uis_edw.VW_SEMESTER ; 

  return ( ay_cd ); 
end;
--
grant execute on uis_utils.get_cur_ay_cd  to public;

-- GET_TERM_YR return the year for the term_cd passed in, and if NULL for the Current Term.
--
-- E.g.:   select   uis_utils.get_term_yr  as term_yr   from dual;
--
create or replace FUNCTION  uis_utils.get_term_yr( term_cd  IN VARCHAR2  default 'RESET' )
   return VARCHAR2  AS this_yr  VARCHAR2( 4 ); 
begin  
  declare this_term_cd 	VARCHAR2( 6 ) ;
  
  begin
     if ( term_cd = 'RESET' ) 
	 then 
		select current_term into this_term_cd  from uis_edw.VW_SEMESTER ;
	 else 
	    this_term_cd := term_cd ;
	 end if;
  
     this_yr := substr( this_term_cd, 2,4 );
  end;
  
  return ( this_yr ); 
end;
--
grant execute on uis_utils.get_term_yr  to public;


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
REPLACE_ABBRV(): Act on a single item for replacement based upon flags passed in.

keep_acronym_flag - Looks for entry in the SMARTCAP table, and uses it for the replacement.
...otherwise the ABBREVIATIONS table is used.

initcap_flag - If no replacement value is found (either SMARTCAP or ABBREVIATIONS) based upon
	the request, an initcap() is performed.  Most likely used in structured settings - e.g., Titles.

use_acronym_set : for Banner Titles (default: 'BANNER') 
	or for Campus Announcements ('ANNOUNCEMENTS')
	or for Course Evaluations ('CRSEVALS')
	...guides which replacement set is used.
	
If no substitutions were made, returns the exact same term passed in - depending on request.
...e.g., if [initcap_flag=Y], then that utility will be ran.

Note that there's a custom acronym table [SMARTCAP] used to override and keep an acronym if one
is found (e.g., for CIO, IT, etc.), otherwise [ABBREVIATIONS] is used.

See:	SMARTCAP() - parses through a string passing each item to this utility.

		team.pop_abbreviations.sql for new entries to act on.
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
   -- SHOULD [keep_acronym_flag] use the [use_acronym_set] condition????
   
   -- str_acted_on := str_to_acton ;	-- Default to what was passed in, for case nothing found.
   str_acted_on := NULL;

   if ( keep_acronym_flag = 'Y' )
   then
      select max( ret_value ) into str_acted_on  from team.SMARTCAP  where upper( term ) = upper( str_to_acton )  and is_active = 'Y'  and dir_display_flag = 'Y' ;
   end if;
   
   if ( str_acted_on is NULL ) 
   then 
      if ( use_acronym_set	= 'BANNER' ) 
      then
         select max( phrase ) into str_acted_on  from team.ABBREVIATIONS where upper( acronym ) = upper( str_to_acton ) and is_abbrv_banner = 'Y' ;
		 
	  elsif ( use_acronym_set	= 'CRSEVALS' ) 
	  then
	     select max( phrase ) into str_acted_on  from team.ABBREVIATIONS where upper( acronym ) = upper( str_to_acton ) and is_abbrv_crs_eval = 'Y' ;
	  
      else		-- Punt and use Campus Announcements...
         select max( phrase ) into str_acted_on  from team.ABBREVIATIONS where upper( acronym ) = upper( str_to_acton ) and is_abbrv_announcements = 'Y' ;

      end if; 
	  
	  if ( str_acted_on is NULL  and  initcap_flag = 'Y' )  -- ...still nothing has been found, initcap() it.
	  then
	     -- initcap() will cap the 'S' on possesive (single quote) or within parens
         if ( lower( str_to_acton )  like '%''s' ) 
         then
            str_acted_on := replace( initcap( str_to_acton ), '''S', '''s' ) ;
         elsif ( lower( str_to_acton )  like '%(s)' ) 
         then 
            str_acted_on := replace( initcap( str_to_acton ), '(S)', '(s)' ) ;
         elsif ( lower( str_to_acton )  like '%(ls)' ) 
         then 
            str_acted_on := replace( initcap( str_to_acton ), '(Ls)', '(LS)' ) ;
         else 
            str_acted_on := initcap( str_to_acton ) ;
         end if;
	  end if;
	  
	  -- ...if its still null, then INITCAP not requested - pass back what was passed in.
	  if ( str_acted_on is NULL )
	  then
	     str_acted_on :=  str_to_acton ;
	  end if;
	  
   end if;
   
   return str_acted_on; 
  
EXCEPTION

   WHEN OTHERS THEN	return  str_acted_on;
   
END ;		-- uis_utils.REPLACE_ABBRV;
--
grant execute on uis_utils.REPLACE_ABBRV  to public;

/* SMARTCAP: Parses a string for replacements based upon flags passed in.

	First string is split by comma, and then by spaces to get at each word.
	...a second pass is made by splitting on [/], and then by spaces.

	Splitting on periods requires too much context - eg, were we at the end of the sentence, was MR. => Mister, ...
	...so skip for now - until it's absolutely wanted.   

Input:

	keep_acronym_flag - see prologue to [uis_utils.REPLACE_ABBRV()]

	initcap_flag - see prologue to [uis_utils.REPLACE_ABBRV()]

	use_acronym_set : for Banner Titles (default: 'BANNER') 
	...or for Campus Announcements ('ANNOUNCEMENTS')
	...or for Course Evaluations ('CRSEVALS')
	...guides which replacement set is used.
	
	title_xlat_flag : Y is for phrases being acted on is a Banner title needing translated, so other flags 
		are set accordingly (eliminiating the need to set them just so).
	
Note;	MAX string size passed in should be 4000, or less;
		Hyphens are not considered a separator (some acronyms use hyphens);
		New lines and charriage returns are not handled (yet);
		
		Title and Departments with the name spelled out along with the acronym will result in double naming.
		...for Departments/orgs, switch to using Banners CodeBook - which has the official name of an orginization.

		...Solution: change Banner to remove redundancy?  ...or try to handle in this utility (error prone)(?).
		...e.g.: this should work:
		
		select 'Office of Engaged Learning Office of Engaged Learning'  str_in
			, regexp_replace('Office of Engaged Learning Office of Engaged Learning', '(.*)(.*)\1', '\1\2')  str_out
		from  dual;
		
*/
--
create or replace function  uis_utils.SMARTCAP( 
   str_to_acton			in VARCHAR2
   , initcap_flag		in varchar2		default 'Y'
   , keep_acronym_flag	in varchar2		default 'Y'
   , use_acronym_set	in VARCHAR2		default 'BANNER'
   , title_xlat_flag	in VARCHAR2		default 'N'
)  return VARCHAR2
is 
  
  l_initcap_flag		VARCHAR2( 1 );	
  l_keep_acronym_flag	VARCHAR2( 1 );
  l_use_acronym_set		VARCHAR2( 10 );
  str_to_act_on_amp		VARCHAR2( 4000 );
  str_acted_on			VARCHAR2( 4000 );
  str_acted_on_4_comma	VARCHAR2( 4000 );	-- Placeholder for string parsed for comma (prelude to parsing for slash)
  delimiter				VARCHAR2( 10 );		-- Handle Slashes (to remove space after a slash was in phrase - assumes word on each side)

BEGIN  
   
   str_acted_on := NULL ;	-- Default to what was passed in, for case nothing found.
   delimiter := ' ';
   
   -- If being called to transform a title, reset flags accordingly.
   --
   l_initcap_flag		:= initcap_flag ;	
   l_keep_acronym_flag	:= keep_acronym_flag ;
   l_use_acronym_set		:= use_acronym_set ;
   
   if ( title_xlat_flag = 'Y' )
   then
      l_initcap_flag		:= 'Y' ;	
      l_keep_acronym_flag	:= 'Y' ;
      l_use_acronym_set		:= 'BANNER' ;
   
   end if;
   
   -- If Crs Evals, set acronym set back - since term-value pairs are more restrictive...
   if ( use_acronym_set	= 'CRSEVALS' )
   then
      l_initcap_flag		:= 'Y' ;	
      l_keep_acronym_flag	:= 'Y' ;
      l_use_acronym_set		:= 'CRSEVALS' ;
   
   end if;
   
   
   -- Before parsing, see if an exact match can be found - kludgy fix for HRs overloading of terms for titles.
   -- ...eg PROF for Professor or Professional, to see if a hard-coded title match can be made.
   -- 
   if ( use_acronym_set	= 'BANNER'  or  use_acronym_set	= 'CRSEVALS')
   then
      select max( phrase ) into str_acted_on  from team.ABBREVIATIONS where upper( acronym ) = upper( str_to_acton ) and is_abbrv_banner = 'Y' ;
	  
      if ( str_acted_on  is not  NULL )  
	  then
	     return( str_acted_on );
	  end if;
	  
      -- Banner Titles (and Department Names (for Course Evals) sometimes embed [&] without spaces - so add them, then remove extra ones...
      str_to_act_on_amp := replace( replace( str_to_acton, '&', ' & ' ), '  ', ' ' );
   
	  -- else its NULL, and we are ready for parsing.
   end if;
   

   -- Split the input on comma(s)[,] and then forward-slash(s)[/] as the delimiter - if they exists...and add back...
   --
   for  c  in ( select trim( regexp_substr( str_to_act_on_amp, '[^,]+', 1, LEVEL )) l  from dual  CONNECT BY LEVEL <= regexp_count( str_to_act_on_amp, '[,]') +1  )
   loop
      -- dbms_output.put_line( c.l );
	  -- Iterate across substring using a [space] as the delimiter...
      --	  
      for  i  in ( select trim( regexp_substr( c.l, '[^ ]+', 1, LEVEL )) l  from dual  CONNECT BY LEVEL <= regexp_count( c.l, ' ') +1  )
      loop
      -- dbms_output.put_line( 'c: i.1 = '|| i.l );
	  
		 -- Some abbreviations are removed - a space can be returned, so trim spaces off...
		 --
	     str_acted_on := trim( str_acted_on || delimiter || uis_utils.REPLACE_ABBRV( i.l, initcap_flag => l_initcap_flag, keep_acronym_flag => l_keep_acronym_flag, use_acronym_set => l_use_acronym_set ) );

      end loop;	  
		 
	  str_acted_on := str_acted_on ||',';	-- ...append a comma we split on

   end loop;	-- string split on commas...
   
   str_acted_on := rtrim( str_acted_on, ',' );	-- ...remove trailing comma
   
   str_acted_on_4_comma := str_acted_on;	str_acted_on := NULL;
   
   -- Now parse on string acted on for commas, and split on slash[/]...
   for  s  in ( select trim( regexp_substr( str_acted_on_4_comma , '[^/]+', 1, LEVEL )) l  from dual  CONNECT BY LEVEL <= regexp_count( str_acted_on_4_comma , '[/]') +1  )
   loop
       -- dbms_output.put_line( s.l );
	   -- Iterate across substring using a [space] as the delimiter...
       --	  
       for  i  in ( select trim( regexp_substr( s.l, '[^ ]+', 1, LEVEL )) l  from dual  CONNECT BY LEVEL <= regexp_count( s.l, ' ') +1  )
       loop
       -- dbms_output.put_line( 's: i.1 = '|| i.l );
	   
	      -- Some abbreviations are removed - a space can be returned, so trim spaces off...
		  --
	      str_acted_on := trim( str_acted_on || delimiter || uis_utils.REPLACE_ABBRV( i.l, initcap_flag => l_initcap_flag, keep_acronym_flag => l_keep_acronym_flag, use_acronym_set => l_use_acronym_set ) );

          -- Reset [delimiter] to space...first word after a slash-split set it to nothing.
	      delimiter := ' ';
       end loop;

       str_acted_on := str_acted_on ||'/';		-- ...append a slash we split on
	   delimiter := '' ;		-- When a slash is detected, the delimiter to use for the next word is [nothing].

   end loop;	-- string split on slashes..		 
	
   str_acted_on := rtrim( str_acted_on, '/' );		-- ...remove trailing [/]

   return ltrim( str_acted_on ); 
  
EXCEPTION

   WHEN OTHERS THEN	return  str_acted_on;
   
END ;		-- uis_utils.SMARTCAP;
--
grant execute on uis_utils.SMARTCAP  to public;

