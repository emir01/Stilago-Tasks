USE [Stilago.TemplateDb]
GO

/****** Object:  StoredProcedure [dbo].[Duplicate]    Script Date: 9/25/2014 2:51:09 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[Duplicate]
	
AS
BEGIN
	-- =================================================================
	-- Explanation: 
	-- The module and page tables are simple duplications for now.
	-- Use INSERT INTO SELECT Syntax and just SET the "SELECT" Id as the parent column.

	-- BASSICALLY WE CAN EXECUTE template and module duplication as much as we want... but there is an issue with
	-- Multiple duplications for tempalte_line.
	-- So we are going to try something else... using only at that "run" duplicated data to duplicate template_module data.

	-- NOT sure if the task requires multiple duplication runs but I think the tmp table aproach is one way to fix the issue because we 
	-- get templates with same parent id after duplication runs
	-- =================================================================


	-- ADDITIONAL STUFF: Initial procedure hat issues when running > 1 call. so we are going to be using tmp tables to store the
	-- 

	-- TMP TABLE CREATION
	-- ==========================================================================================================================================================

	Create Table dbo.TempTemplateDuplicates
	(
		[id] [int]  NOT NULL,
		[site_id] [nvarchar](50) NOT NULL,
		[name] [nvarchar](max) NOT NULL,
		[descr] [nvarchar](500) NOT NULL,
		[status] [bit] NOT NULL,
		[datum] [datetime] NOT NULL,
		[tmp] [nvarchar](250) NOT NULL,
		[parent_id] [int] NULL,
		[structure] [nvarchar](max) NOT NULL,
	);

	Create Table dbo.TempTemplateModuleDuplicates
	(
		[id] [int] NOT NULL,
		[page] [nvarchar](50) NOT NULL,
		[name] [nvarchar](50) NOT NULL,
		[status] [bit] NOT NULL,
		[descr] [nvarchar](500) NOT NULL,
		[site_id] [int] NOT NULL,
		[defaultposition] [int] NOT NULL,
		[parent_id] [int] NULL,
		[hidden] [bit] NOT NULL,
	);

	-- DUPLICATE TEMPLATE MODULE
	-- ==========================================================================================================================================================

	-- Duplicate module table first inside tmp table

	INSERT INTO TempTemplateModuleDuplicates
	(
		 id
		,page
		,name
		,status
		,descr
		,site_id
		,defaultposition
		,parent_id
		,hidden
	)
	SELECT
		 tm.id
		,tm.page
		,tm.name
		,tm.status
		,tm.descr
		,tm.site_id
		,tm.defaultposition
		,tm.id
		,tm.hidden
	
	FROM template_module tm

	-- THE INSERT CURRENT DUPLICATES INTO ACTUAL TABLE

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
	
	FROM TempTemplateModuleDuplicates as tm

	-- DUPLICATE TEMPLATE TABLE
	-- ==========================================================================================================================================================

	-- First into tmp table

	INSERT INTO TempTemplateDuplicates
	(
		 id
		,site_id
		,name
		,descr
		,status
		,datum
		,tmp
		,parent_id
		,structure
	)
	SELECT 
	     t.id
		,t.site_id
		,'Duplicate '+t.name
		,t.descr
		,t.status
		,t.datum
		,t.tmp
		,t.id
		,t.structure
	FROM template as t

	-- Then into actual table
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
	FROM TempTemplateDuplicates as t

	-- ==========================================================================================================================================================
	-- ==========================================================================================================================================================
	--						RUN DUPLICATE ON TEMPLATE LINE
	-- ==========================================================================================================================================================
	-- do it on the same principle as before but run extra selections for 
	-- the reference FK columns. Now using tmp tables that contain only the duplicated values should work and allow multiple duplication
	-- ==========================================================================================================================================================

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
			SELECT it.id 
			FROM dbo.template as it 
			WHERE it.parent_id = tl.tid
			
			-- EXCLUDE ALL ORIGINALS FROM BEFORE DUPLICATION
			AND  it.id NOT IN(Select Id from dbo.TempTemplateDuplicates)
		 ) -- template.id -- select from template table
		,(
			SELECT itm.id 
			FROM dbo.template_module as itm 
			WHERE itm.parent_id = tl.mid 
			
			-- EXCLUDE ALL ORIGINALS FROM BEFORE DUPLICATION
			AND  itm.id NOT IN(Select Id from dbo.TempTemplateModuleDuplicates)
		 )  -- module.id -- select from module table
		,tl.ord
		,tl.tip
		,tl.id -- parent id
		,tl.languages2
		,tl.hidden2

	FROM template_line AS tl
		INNER JOIN template AS t ON tl.tid = t.id
		INNER JOIN template_module AS tm ON tl.mid = tm.id

	
	-- BEFORE WRAPPING UP CLEAR TMP TABLES
	 DROP TABLE dbo.TempTemplateDuplicates;
	  DROP TABLE dbo.TempTemplateModuleDuplicates;

END
GO


