USE [Stilago.TemplateDb]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[sp_ClearAllData]

SELECT	'Return Value' = @return_value

GO
