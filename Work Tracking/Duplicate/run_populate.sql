USE [Stilago.TemplateDb]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[sp_PopulateWithData]

SELECT	'Return Value' = @return_value

GO
