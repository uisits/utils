/*
File:	utils/oracle/java/os_cmd.pkgb

Desc:	Oracle front end utility wrappers for calling Java code.
		
Usage:
 
Note / Warning:

See also:
		[./oscommand.java] - actual java code being called.
		
		[datafeeds/CollegiateLink/sql] - initially introduced to support CollegiateLink Student Events
		
Author:	Keagan Lidwell
*/

create or replace PACKAGE uis_utils.os_cmd AS
    FUNCTION oscomm (p_command IN VARCHAR2 ) RETURN VARCHAR2;
    FUNCTION utc_time (l_time VARCHAR2) RETURN VARCHAR2;
    FUNCTION to_sha256sum (l_var VARCHAR2) RETURN VARCHAR2;
    FUNCTION substring_with_delimiter (l_string VARCHAR2, l_delimiter VARCHAR2, l_index VARCHAR2) RETURN VARCHAR2;
    FUNCTION to_date  (l_utc VARCHAR2) RETURN VARCHAR2;
    FUNCTION create_file (l_name VARCHAR2, l_text CLOB) RETURN VARCHAR2;
END;

-- !*!*!*!*!*!*!* BODY !*!*!*!*!*!*!*!*!*

create or replace PACKAGE BODY os_cmd AS
  --FUNCTION TO USE JAVA CODE (refreshed from Keagan L.s version 1/27/2017
  
  FUNCTION oscomm (p_command IN VARCHAR2) RETURN VARCHAR2
  AS LANGUAGE JAVA
  NAME 'OSCommand.executeCommand (java.lang.String) return java.lang.String';
  
  FUNCTION utc_time (l_time varchar2) return varchar2 as
  BEGIN
    return oscomm('/bin/date --date="' || l_time || '" +%s%3N');
  END;
  
  FUNCTION to_sha256sum (l_var VARCHAR2) RETURN VARCHAR2 AS
  BEGIN
    return oscomm('/bin/echo ' || '"' || l_var || '"' || ' | /usr/bin/sha256sum');
  END;
  
  FUNCTION substring_with_delimiter (l_string VARCHAR2, l_delimiter VARCHAR2, l_index VARCHAR2) RETURN VARCHAR2 AS
  BEGIN
    return oscomm('/bin/echo ' || '"' || l_string || '"' || ' | /usr/bin/cut -d"' || l_delimiter || '" -f' || l_index);
  END;
  
  FUNCTION to_date (l_utc VARCHAR2) RETURN VARCHAR2 AS
  BEGIN
    return oscomm('/bin/date -d @' || l_utc || ' +"%F %T"');
  END;
  
  FUNCTION create_file(l_name VARCHAR2, l_text CLOB) RETURN VARCHAR2 AS
  BEGIN
    return oscomm('/bin/echo "'|| l_text || '" > ' || l_name);
  END;
end;
