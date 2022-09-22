/*
File:	utils/sqlserver/replace_cyrillic.sql

		!*!*!* SEE PROLOGUE BELOW *!*!*!*
*/
USE [uis_utils] ;


ALTER
create function  dbo.replace_cyrillic (
	@str_in			varchar( MAX ) = 'HELP'	-- to get prologue
)
returns nvarchar( MAX )
as
begin
   
   declare	@cyrillic_free	varchar( MAX );
   
   if (  @str_in is NULL  or upper(@str_in) = 'HELP'  or @str_in = '' ) 
   begin
       set @cyrillic_free = '
File:	utils\sqlserver\replace_cyrillic.sql

Desc:	This utility accepts string input [varchar(MAX)], and returns the same string with
		Cyrllic characters replaced with an English equivalent.

		E.g.: { æøåáäĺćçčéđńőöřůýţžš } chars are replaced with => { ?oaaalcccednooruytzs } 
		...respectively.
		
		str_in : (default = Help, returns this Prologue);
		
Note:	NA
		
Enhancements:
		
See:	

Author: Vern Huber - Sept. 2022
		
Caveats / Things to Consider:
		
Examples:
	select uis_utils.dbo.replace_cyrrlic(''HELP'') ;
	...provides this HELP prologue
	
	select  uis_utils.dbo.split_string_word(''Niccolò'')  ;
	...returns => Niccolo
'
      return @cyrillic_free ;
   end
-- ******************************** END of HELP **************************************

	set @cyrillic_free = CONVERT( varchar( MAX ), @str_in )  COLLATE Cyrillic_General_CI_AI ;

   return( @cyrillic_free );
	
end  --  End of [ dbo.replace_cyrillic ]  -- commit


grant EXECUTE on uis_utils.dbo.replace_cyrillic  to PUBLIC ;
grant REFERENCES on uis_utils.dbo.replace_cyrillic  to PUBLIC ;

