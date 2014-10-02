USE [Stilago.TemplateDb]
GO

/****** Object:  StoredProcedure [dbo].[Duplicate]    Script Date: 9/25/2014 3:41:01 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Duplicate]
	
AS
BEGIN
	-- =================================================================
	-- Explanation: 
	-- The module and page tables are simple duplications for now.
	-- Use INSERT INTO SELECT Syntax and just SET the "SELECT" Id as the parent column.

	
	-- =================================================================


	
	-- Duplicate module table

	INSERT INTO template_module
	(
		 page
		,name
		,status
		,descr
		,site_id
		,defaultposition
		,parent_id
		,hidden
	)
	SELECT
		 tm.page
		,tm.name
		,tm.status
		,tm.descr
		,tm.site_id
		,tm.defaultposition
		,tm.id
		,tm.hidden
	
	FROM template_module tm

	-- Duplicate everything in page table

	INSERT INTO template
	(
		 site_id
		,name
		,descr
		,status
		,datum
		,tmp
		,parent_id
		,structure
	)
	SELECT 
		 t.site_id
		,'Duplicate '+t.name
		,t.descr
		,t.status
		,t.datum
		,t.tmp
		,t.id
		,t.structure
	FROM template as t

	-- ============================================================================
	-- ============================================================================
	--						RUN DUPLICATE ON TEMPLATE LINE
	-- ============================================================================
	-- do it on the same principle as before but run extra selections for 
	-- the reference key tables
	-- ============================================================================

	INSERT INTO template_line
	(
		 tid -- the template id -- calc column - joined
		,mid-- the module id -- calc column - joined
		,ord
		,tip
		,parent_id
		,languages2
		,hidden2
	)
	SELECT 
		 (
			SELECT it.id FROM template as it WHERE it.parent_id = tl.tid
		 ) -- template.id -- select from template table
		,(
			SELECT itm.id FROM template_module as itm WHERE itm.parent_id = tl.mid 
		 )  -- module.id -- select from module table
		,tl.ord
		,tl.tip
		,tl.id -- parent id
		,tl.languages2
		,tl.hidden2

	FROM template_line AS tl
		INNER JOIN template AS t ON tl.tid = t.id
		INNER JOIN template_module AS tm ON tl.mid = tm.id

END



GO


