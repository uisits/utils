/*
File:	utils\sqlserver\split_string_word.sql

		!*!*!* SEE PROLOGUE BELOW *!*!*!*
*/
USE [uis_utils] ;


ALTER FUNCTION [dbo].[split_string_word] (
   @split_this			nvarchar( max ) = 'HELP'	-- to get prologue
   , @word_delimiter	nvarchar( 100 ) = 'PUNT'
   , @include_delimiter	nvarchar( 1 )	= 'N'		-- Should delimiter be included in result 
   , @return_first_part	nvarchar( 1 )	= 'Y'		-- Return substring before (Y) or after (N) the delimiter
)
RETURNS NVARCHAR( max )
AS
BEGIN
   
   declare	@sub_this	nvarchar( max );
   
   if (  @split_this is NULL  or upper(@split_this) = 'HELP'  or @split_this = '' ) 
   begin
       set @sub_this = '
File:	utils\sqlserver\split_string_word.sql

Desc:	This utility accepts string input, and returns a substring based upon the
		word-delimiter passed in.

		split_this : Help Prologue returned;
		
		word_delimiter : File does not exist;
		
		include_delimiter : File exist, but is empty;
		
		return_first_part : File exist, and the value is the size of the file;
		
Note:	
		
Enhancements:
		
See:	

Author: Vern Huber - Dec. 2021
		
Caveats / Things to Consider:
		
Examples:
	select uis_utils.dbo.split_string_word(''HELP'',''PUNT'',''N'',''Y'') ;
	...provides this HELP prologue
	
	select  uis_utils.dbo.split_string_word(''testing 1 2 3 testing'',''test'',''Y'',''Y'')  ;
	...results in:
	NY: null
	YY: test 
	YN: testing 1 2 3 testing
	NN: ting 1 2 3 testing
'
      return @sub_this ;
   end
-- ******************************** END of HELP **************************************

   -- Declare variables...
   declare @delim_sz		int;
   declare @delim_fnd_at	int;
   declare @delim_offset	int;
	
   set @delim_fnd_at = charindex( @word_delimiter, @split_this, 0 ) ;
   
   if ( @delim_fnd_at = 0 )		-- Delimiter not found - DONE, nothing else to do...
   begin 
      return( NULL );
   end;
   
   set @delim_sz = len( @word_delimiter );
   set @delim_offset = @delim_sz;
    
   if @return_first_part = 'Y'
   begin
      if @include_delimiter = 'N'
      begin
         set @delim_offset = 0;
      end;
	  
      set @sub_this = substring( @split_this, 0, @delim_fnd_at + @delim_offset );
   end;	
   else
   begin
      if @include_delimiter = 'Y'
      begin
         set @delim_offset = 0;
      end;
      set @sub_this = substring( @split_this, @delim_fnd_at + @delim_offset, len( @split_this ) );
   end;

   return( @sub_this );
	
end  --  End of [ dbo.split_string_word ]  -- commit


