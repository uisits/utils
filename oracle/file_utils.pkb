/*
File:	utils/oracle/file_utils.pkb

Desc:	Utilities commonly needed when working with filename (fully qualified or otherwise).

Note:	None at this time;

Enhancements:


Author:	Vern Huber
		
Usage:	
    
*/
CREATE OR REPLACE PACKAGE uis_utils.file_utils  as

   TYPE T_ARRAY IS TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER; 
   CRLF CONSTANT VARCHAR2(2 CHAR) := chr(13)||chr(10);
	  

   FUNCTION basename( 
      qualified_filename IN VARCHAR2,  file_extension IN VARCHAR2 DEFAULT NULL,  path_separator IN CHAR DEFAULT '/'
   )  RETURN VARCHAR2;

END ;


CREATE OR REPLACE PACKAGE BODY uis_utils.file_utils  as

-- qualified_filename : qualified filename (has full or partial path leading to filename)
-- file_extension		: Extension of file - if you want the file extension removed from the basename returned; E.g.: '.txt'
-- path_separator	  : Separator used in path to delimit directories - if its something other than a [/];
--
FUNCTION basename( qualified_filename IN VARCHAR2,  file_extension IN VARCHAR2 DEFAULT NULL,  path_separator IN CHAR DEFAULT '/' )
   RETURN VARCHAR2
IS
   v_basename VARCHAR2(256);
   
BEGIN
   v_basename := SUBSTR( qualified_filename, INSTR( qualified_filename, path_separator, -1) +1 );
   
   IF  file_extension  IS NOT NULL THEN
      v_basename := SUBSTR(v_basename, 1, INSTR(v_basename, file_extension, -1)-1);
   END IF;

   RETURN v_basename;

END;	-- end of [basename()]
		
END;	-- end of package FILE_UTILS
	