USE [master]

-- Eg:  exec dbo.SP_FindAllReferences 'edw_facsec'
--
CREATE PROCEDURE [dbo].[SP_FindAllReferences]
@targetText nvarchar(128)
AS
BEGIN
    SET NOCOUNT ON;

    declare @origdb nvarchar(128)
    select @origdb = db_name()

    declare @sql nvarchar(1000)

    set @sql = 'USE [' + @origdb +'];' 
    set @sql += 'select object_name(m.object_id), m.* '
    set @sql += 'from sys.sql_modules m  where m.definition like N' + CHAR(39) + '%' + @targetText + '%' + CHAR(39)

    exec (@sql)

    SET NOCOUNT OFF;
END
