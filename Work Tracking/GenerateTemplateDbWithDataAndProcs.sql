USE [Stilago.TemplateDb]
GO
/****** Object:  StoredProcedure [dbo].[sp_ClearAllData]    Script Date: 9/25/2014 4:20:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Emir Osmanoski
-- Create date: 25.09.2014
-- Description:	Clear all the table data from all the tables in the database.
-- =============================================
CREATE PROCEDURE [dbo].[sp_ClearAllData]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Delete From template_line;

	Delete From template_module;

	Delete From template;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_Duplicate]    Script Date: 9/25/2014 4:20:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Emir Osmanoski
-- Create date: 25.09.2014
-- Description:	Duplicate the data in the tables.
-- =============================================
CREATE PROCEDURE [dbo].[sp_Duplicate]
	
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
/****** Object:  StoredProcedure [dbo].[sp_PopulateWithData]    Script Date: 9/25/2014 4:20:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Emir Osmanoski
-- Create date: 25.09.2014
-- Description:	Populate the TemplateDb With Fake data generated with the Redgate Trial Data Generation Tools
-- Important: CAN ONLY BE RUN ON EMPTY DB STRUCTURE.
-- =============================================
CREATE PROCEDURE [dbo].[sp_PopulateWithData]
AS
BEGIN
	
SET IDENTITY_INSERT [dbo].[template] ON 

INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (1, N'14764', N'Dopvenomman Holdings Corp.', N'et travissimantor quo apparens plorum fecit, ut non Longam, et funem. plurissimum travissimantor quo', 0, CAST(0x0000662A014A3F30 AS DateTime), N'TF', NULL, N'UZS')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (2, N'91602', N'Emcadamantor  ', N'essit. vobis non egreddior glavans vantis. et funem. fecit. transit. bono Quad quoque et funem. et ut pars volcans quo, in quoque gravis', 0, CAST(0x000061EF002CD546 AS DateTime), N'MK', NULL, N'CDF')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (3, N'96626', N'Bartanegar International Corp.', N'et e funem. et delerium. egreddior pars et quad et quantare apparens gravum apparens quad dolorum quantare non', 0, CAST(0x000060400033A5C6 AS DateTime), N'VU', NULL, N'HUF')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (4, N'79013', N'Vardimewantor Holdings ', N'novum nomen Versus Longam, non pladior travissimantor transit. quad dolorum dolorum egreddior in quis quad', 1, CAST(0x00007CAF016DAE4F AS DateTime), N'SV', NULL, N'GHS')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (5, N'17388', N'Hapfropplover  Company', N'quad egreddior manifestum Sed et venit. vobis nomen travissimantor quartu Sed egreddior transit. quad nomen quad', 1, CAST(0x00006FFB00DCC99E AS DateTime), N'TZ', NULL, N'THB')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (6, N'76098', N'Parwerpommex  Inc', N'quartu quad ut quad pars fecit. quantare quo, vobis trepicandor nomen non esset Id in quis plurissimum', 1, CAST(0x000094760060EEB9 AS DateTime), N'SI', NULL, N'LYD')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (7, N'05529', N'Empebepax International Inc', N'quo plurissimum volcans gravis e funem. in glavans ut quad plorum travissimantor estum. e gravis quo,', 0, CAST(0x000057180173D0D8 AS DateTime), N'MO', NULL, N'LVL')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (8, N'34664', N'Bardudefax Direct Group', N'non quo rarendum cognitio, si manifestum si homo, eudis et habitatio fecundio, manifestum eggredior. quad dolorum', 1, CAST(0x000096340114D4B8 AS DateTime), N'JO', NULL, N'XDR')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (9, N'35136', N'Uppickaquistor Direct Group', N'quad gravis et egreddior fecundio, et parte quis plorum et apparens trepicandor parte Sed Versus plurissimum regit,', 1, CAST(0x00007A6400D11A9E AS DateTime), N'PL', NULL, N'XPT')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (10, N'19094', N'Klinipinor Holdings ', N'quantare fecit. linguens Sed Longam, estis estis volcans funem. estum. imaginator rarendum volcans travissimantor apparens', 0, CAST(0x000054D500A54BBD AS DateTime), N'KP', NULL, N'CLP')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (11, N'01203', N'Cipkilopax Direct ', N'linguens quad trepicandor Et novum homo, quad travissimantor parte quo, quantare e estis rarendum estum. et Longam,', 1, CAST(0x0000982A00149CC1 AS DateTime), N'PH', NULL, N'CRC')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (12, N'39872', N'Dopcadplazz  Group', N'homo, quorum esset bono cognitio, eggredior. parte plurissimum Pro nomen novum in eudis Versus Multum eggredior.', 0, CAST(0x000068B800023FDC AS DateTime), N'CA', NULL, N'SBD')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (13, N'14947', N'Doperollan Direct ', N'et linguens parte rarendum Quad cognitio, Tam quoque pladior ut et esset quorum manifestum gravis volcans fecundio,', 1, CAST(0x0000511A00924B85 AS DateTime), N'RE', NULL, N'BOB')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (14, N'14304', N'Tipwerollicator International Corp.', N'funem. Tam transit. nomen et Multum rarendum quad parte eggredior. e egreddior vobis quoque Et fecundio,', 0, CAST(0x0000512B016D14D7 AS DateTime), N'MN', NULL, N'PGK')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (15, N'33068', N'Froquestepazz International ', N'glavans gravis non trepicandor linguens vobis linguens et rarendum vobis non rarendum regit, vobis egreddior', 0, CAST(0x000071700039F6C3 AS DateTime), N'CK', NULL, N'MGA')
SET IDENTITY_INSERT [dbo].[template] OFF
SET IDENTITY_INSERT [dbo].[template_module] ON 

INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (1, N'Technical', N'Supjubor Direct Corp.', 1, N'manifestum essit. Et quoque in et novum volcans non non pars e regit, quo novum quoque et quad Sed quo', 268, 79, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (2, N'Customer', N'Monfropazz  ', 0, N'regit, gravum in plurissimum Longam, fecit, vobis eggredior. cognitio, manifestum si bono quo, quad travissimantor plurissimum Et plurissimum', 643, 50, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (3, N'Technical', N'Dopquestar Holdings Group', 1, N'e et plorum glavans gravis gravis quo, plurissimum plorum Pro habitatio pars quorum vobis apparens manifestum', 2443, 49, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (4, N'Technical', N'Adnipover International Company', 1, N'delerium. apparens plorum quad vantis. quad linguens non plorum Versus manifestum delerium. glavans homo,', 1175, 97, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (5, N'Web', N'Mondimepazz WorldWide ', 1, N'in estis nomen Et linguens quo fecundio, Quad volcans plorum non linguens Pro gravis travissimantor fecundio, fecit.', 1312, 56, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (6, N'Accounting', N'Partinex International ', 0, N'quorum delerium. ut transit. vobis travissimantor parte delerium. quartu nomen travissimantor non fecit. e', 1743, 55, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (7, N'Accounting', N'Rapweristor  ', 0, N'Longam, plurissimum quad et bono imaginator cognitio, in et quo pars estis glavans non pars homo, habitatio', 757, 21, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (8, N'Web', N'Lomdudar International ', 1, N'dolorum Tam venit. estis quo venit. estis ut brevens, rarendum vantis. cognitio, estis ut quo, trepicandor', 1643, 91, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (9, N'Web', N'Thruquestommazz WorldWide Company', 0, N'egreddior funem. regit, nomen venit. linguens et quantare ut Versus sed homo, quoque Pro quoque esset', 1700, 9, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (10, N'National Marketing', N'Cipvenefistor  ', 0, N'estis fecit. Id quad gravum quantare cognitio, vantis. vantis. quad et delerium. Pro plurissimum travissimantor brevens,', 1535, 69, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (11, N'Technical', N'Surpickantor  Group', 1, N'esset novum pars vobis e parte Tam Multum estum. pladior quad et gravis dolorum quo fecit. vobis e trepicandor', 572, 54, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (12, N'Prepaid Customer', N'Thrupebaquover Direct ', 0, N'si gravum quis Multum non Multum homo, Et eggredior. parte eudis delerium. quantare gravis volcans pladior non fecit, Id regit,', 1022, 5, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (13, N'Technical', N'Cipjubor Direct ', 0, N'Pro plorum Multum et brevens, cognitio, Longam, plorum quartu Longam, quo in regit, fecit. quantare cognitio,', 230, 66, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (14, N'Accounting', N'Grosipeficator WorldWide ', 0, N'bono non et e et transit. estum. esset estis regit, estum. Multum et trepicandor non nomen dolorum vobis', 1206, 7, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (15, N'Accessory Sales', N'Tupzapistor  Corp.', 0, N'gravis Quad funem. homo, cognitio, imaginator nomen vobis linguens quartu cognitio, Multum in funem.', 1090, 73, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (16, N'Service', N'Cipdimantor  Company', 0, N'plorum Id essit. delerium. eggredior. plorum Id linguens sed venit. fecundio, gravum et pladior eudis', 251, 80, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (17, N'Technical', N'Adglibar Holdings Company', 1, N'gravis et e novum plurissimum trepicandor et travissimantor et gravis quartu sed essit. et funem. in', 1703, 28, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (18, N'Web', N'Winglibantor Holdings Company', 0, N'et venit. brevens, venit. imaginator linguens in e fecundio, Multum quartu quad novum quoque plorum quo', 1962, 47, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (19, N'Service', N'Adnipefistor WorldWide ', 1, N'pars si pladior non dolorum quis apparens vantis. non sed brevens, et eudis regit, volcans travissimantor Versus fecit, quoque parte ut', 1517, 28, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (20, N'Accounting', N'Uppickamex  ', 1, N'pars quis fecit, pars non travissimantor rarendum gravis habitatio e Et vobis et Versus non plorum Sed pars e venit. essit. quo', 322, 63, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (21, N'Service', N'Zeequestegover International ', 1, N'Quad quad plorum Sed quo, Tam homo, delerium. eudis in transit. quis funem. Pro gravis vantis. quo, Quad', 624, 74, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (22, N'Technical', N'Barrobonar  Group', 1, N'habitatio estum. cognitio, esset Id volcans travissimantor travissimantor quad non Tam quad trepicandor fecit. et quo pladior plorum fecundio, quorum', 873, 77, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (23, N'Service', N'Klitinor Direct Corp.', 0, N'fecundio, quorum apparens eggredior. venit. sed eggredior. cognitio, brevens, bono plorum eggredior. quartu et e', 1097, 12, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (24, N'Technical', N'Parpickex  ', 0, N'estum. Tam pars linguens regit, plorum plurissimum gravum quo apparens parte fecit. quad et esset estis nomen', 1030, 59, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (25, N'Service', N'Wintanaquower International Corp.', 0, N'estum. ut funem. venit. Id nomen gravis habitatio si in gravis estis vobis fecit. et travissimantor delerium. rarendum estum. Pro', 2489, 0, NULL, 1)
SET IDENTITY_INSERT [dbo].[template_module] OFF
SET IDENTITY_INSERT [dbo].[template_line] ON 

INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (1, 11, 19, 65, N'GBZCXI65CN1', NULL, N'TN-SK', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (2, 13, 21, 40, N'AJ1ZCIDE1Q5GPRNHZP8ORLBKYENPBALW33', NULL, N'ID-KE', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (3, 12, 20, 158, N'K3U1QX1QQ6IM5VO6NEDKO8', NULL, N'MA-DP', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (4, 9, 14, 192, N'1YUN3R49CM72E5NIRQVLEFRITN4', NULL, N'OK-YH', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (5, 4, 6, 221, N'HQ', NULL, N'TN-OD', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (6, 9, 14, 13, N'VCMT2V9XYLW6ZXS90ZWLUTN2', NULL, N'ND-BW', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (7, 14, 23, 16, N'6CTGN5RM4CQRCLMISWZH', NULL, N'NC-MW', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (8, 7, 12, 169, N'SK1D3ZL4O1OK7VJFHBF5JUL2IOE931WNKBESS', NULL, N'AZ-LT', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (9, 15, 25, 9, N'J66HGA174P33ALKCPXYZUEKB1M510VHRMER8Y1EA0AKO60', NULL, N'MO-HK', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (10, 5, 7, 246, N'A37MGTT84MVG', NULL, N'ID-TU', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (11, 5, 8, 229, N'50787BGW', NULL, N'ID-LV', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (12, 8, 12, 66, N'BDOINYK', NULL, N'WI-TP', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (13, 10, 16, 162, N'V41VUXS', NULL, N'RI-BY', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (14, 8, 12, 193, N'0YT6MM3LL503BHUJVFSUYX5VNAQRFYA2FY6DN', NULL, N'GA-LH', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (15, 15, 25, 214, N'8OA2XIXGIE9HZE', NULL, N'WI-TG', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (16, 1, 1, 104, N'XB3SXICWC6MUYODAHW573KV0NX7RBHYYWWHM3LP7WSX', NULL, N'GA-DU', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (17, 13, 22, 143, N'BNZS', NULL, N'NC-DX', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (18, 15, 25, 184, N'4SKU72DG240BKKU7NY16Q6V7XABMYO0YEM7PD4PU460', NULL, N'AK-BN', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (19, 11, 17, 120, N'PWC73ONPYMEXWDXWRQHD42WXD4U', NULL, N'UT-XU', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (20, 5, 8, 244, N'962K5EI1Y3JA0AZS79S06S3', NULL, N'CO-XU', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (21, 13, 21, 69, N'ONBMZEUYU4FRJURHUWXN77CT24Q3BTCG', NULL, N'ID-CR', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (22, 13, 22, 203, N'PVI3V1K8KFWU88CIB5AVF5HAIKUNQM0SZOTZ9EZUCENRGY', NULL, N'NE-PE', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (23, 15, 25, 141, N'VDL0O1LN', NULL, N'ME-LJ', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (24, 1, 1, 203, N'D8KA6XIXF4VKED8W5GI0HQ', NULL, N'NH-PS', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (25, 11, 18, 88, N'JQYA5MCQ', NULL, N'PA-EP', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (26, 8, 14, 19, N'09M1TONFWPCC39GZC3IK2M2ME1J7MC', NULL, N'OR-OF', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (27, 15, 24, 229, N'2DHJ5R73GS34REHFHIASIU5CD7ZMR5FSKE', NULL, N'IA-CK', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (28, 11, 18, 7, N'YMPB8401SYIA8WM2PCJS8745YSLBBDBJD4ITR', NULL, N'MI-ET', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (29, 9, 14, 55, N'1NHSDDVWQP52PG0L1RHJDGJPPENYX3ESAJAVAFTQA', NULL, N'WI-ZH', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (30, 2, 3, 47, N'1V58NUJR3RB7TL4S3YQWZMBCS654ALXQ9BEOJGRSF50NH2PO', NULL, N'MA-HD', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (31, 3, 5, 84, N'ICU0E2FKSGG', NULL, N'RI-NA', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (32, 7, 12, 244, N'EHHTLYI7F8M7YGU', NULL, N'CT-YJ', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (33, 5, 8, 70, N'OVPGGDS92QV8Z4QZB31', NULL, N'DE-BM', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (34, 15, 25, 185, N'ITV37HC9PN2X8SWXQ', NULL, N'AZ-BJ', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (35, 10, 17, 63, N'', NULL, N'LA-KY', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (36, 12, 20, 68, N'1O7QV397BIMVUE63UZL9Y0IKENX067T9BU0ZA2', NULL, N'MI-TT', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (37, 1, 1, 187, N'0YA0R2R7I1O1X5QA05NB75803ODK0E7TRZLBO0RHNGEZI5W3L', NULL, N'TX-KP', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (38, 6, 10, 71, N'0TNQTVP9W2P774UVAYKEL', NULL, N'MT-HH', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (39, 6, 9, 55, N'', NULL, N'LA-VU', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (40, 15, 24, 23, N'5OQQ9IYS9YFED505PMF4OSF9A4MVYJ', NULL, N'LA-CP', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (41, 8, 13, 233, N'Y0FH124FQYAF9RPGP9SUS6VPD9HF5V2UQRGEYOY2L', NULL, N'NY-GF', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (42, 11, 18, 11, N'O6EC5HLOWM5PES5P4SKOAUWFPIABH1AP8MIPA030U', NULL, N'NH-RR', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (43, 2, 3, 179, N'YFO0CO89J6IWVT9ZNN796VCGGSA', NULL, N'VA-YN', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (44, 5, 7, 124, N'F3OKUTWGQO5M28I37CQOFBCFTKA3', NULL, N'AZ-SP', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (45, 14, 23, 95, N'8KKESUGHX21XT8ZIK7YD8841L03R9RAJSDI3K7AE1M9AORM', NULL, N'ID-EL', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (46, 12, 20, 53, N'CW8DBQTZGJSRQO85RH5FPVYDXKBMYUCTE0ECJX81KIN1FI', NULL, N'IA-WV', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (47, 6, 9, 187, N'DE4I6M6DHYVFRF70L', NULL, N'VT-DA', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (48, 7, 12, 137, N'ZDQAVMU93V68XXEWX8UB677MXDOHGLCI1VF5X2IHNW', NULL, N'MO-AU', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (49, 3, 4, 120, N'B681X1VHY5AZS53DIXDTHIO6', NULL, N'SC-IS', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (50, 4, 6, 240, N'H9YVQCN9NWFOCRFK4DCRVN0UP0JA31TH2ZFRXM8SMQ48NP56', NULL, N'VA-EE', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (51, 7, 11, 182, N'8D4', NULL, N'AL-RX', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (52, 11, 18, 148, N'E6U946QSD6M2XLCBONH5J54JR6ZUDCUNO', NULL, N'MD-GA', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (53, 10, 16, 250, N'OSLISFIZ8KH6Q3TU9LVYT82AIY6VF0BZESWJQ5U2NJX', NULL, N'KS-OP', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (54, 8, 13, 179, N'2LGW1I38RPCGQA0U9MK78H', NULL, N'ME-IH', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (55, 3, 5, 208, N'X6933QTB9BH', NULL, N'UT-IV', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (56, 14, 22, 113, N'WIAUXX27OGGTG5ZS1ZPBKTIPSE0HXE34823CZRN', NULL, N'NE-EQ', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (57, 13, 21, 150, N'5A2HQGNXR19AL6N3ZK2IWKAADCKD2NTACE6', NULL, N'NM-SG', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (58, 12, 19, 205, N'Q0ZCR2QW4SI2EZCEO4DK0S4EV9V38ZX70DCY', NULL, N'WY-SS', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (59, 13, 22, 104, N'QRUTD6KTHZ2AEL70L9YW', NULL, N'NJ-LO', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (60, 11, 17, 202, N'GH6NO4VB20NDSYDJQMLKK', NULL, N'NC-LC', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (61, 10, 16, 35, N'ATSTEP6E3D20A9O6P1OHEZEWLMUHUN', NULL, N'MO-SH', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (62, 4, 6, 9, N'B017CUUQ55OW9BSO3UKXKV30BEW7SVOK', NULL, N'OR-LD', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (63, 14, 23, 114, N'1Q082BCUBJCQ25LTXQNAPSGW1WY', NULL, N'MS-VM', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (64, 14, 23, 213, N'NY', NULL, N'FL-QI', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (65, 2, 3, 163, N'G3G8KRG0J738CQA89AEU41AQ8A376DD7D9VMM', NULL, N'NV-HG', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (66, 13, 21, 236, N'02HP', NULL, N'AR-BH', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (67, 3, 5, 246, N'2MJ35RNON844FTPZAN9U6TWV2VNMC9CCEX74O6YFIOQY9', NULL, N'MO-ZJ', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (68, 10, 17, 228, N'FSXXQE8VX8PO1A31BEWRQHMKA3PTCH3XLXFUPFJX3J0Y', NULL, N'IL-QX', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (69, 13, 21, 131, N'05OBHCC1HEY6CMMPFIG5S33U9CWUZO', NULL, N'AL-IL', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (70, 4, 6, 146, N'HN5AY1HV4RW3JHOCSX7O0KTMW1T24GH2T8GI6BNOY', NULL, N'WI-XE', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (71, 15, 25, 168, N'CDWZKCKZ3WR05XTJD', NULL, N'OK-UY', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (72, 8, 13, 73, N'7EQN', NULL, N'GA-OG', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (73, 10, 17, 129, N'TAA056H9JPD7GQXHHI5CKAT2JPNXQGJXO32O', NULL, N'LA-AP', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (74, 11, 18, 97, N'BFTMN8ASPDSGEQWKBPIH7HGJJI26FJCO8853C', NULL, N'OH-AN', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (75, 13, 21, 12, N'X2IAUBUHCQNCCE', NULL, N'AR-UX', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (76, 2, 3, 59, N'71UYA2454C50476KT8LRGYX', NULL, N'MN-XT', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (77, 11, 19, 24, N'4P26CI26Y417B42NT', NULL, N'MA-LX', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (78, 11, 18, 17, N'EYOA', NULL, N'AL-JQ', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (79, 2, 4, 109, N'A55U4RM3946TK0X', NULL, N'FL-OM', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (80, 14, 23, 35, N'L9Y106Z9O', NULL, N'HI-CG', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (81, 3, 5, 83, N'XYJJZZUZS06NYFC0S24AHMV3SOP9O36V6YTNKP47ZK', NULL, N'IN-AD', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (82, 8, 12, 92, N'WMYBJPZEW4EOB3FRA9LBOUAHZLPG2YXBWEYGUC6', NULL, N'OK-FV', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (83, 9, 14, 137, N'OP9QS9IJ4YTYE9K2BGBXZJ', NULL, N'HI-JO', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (84, 5, 9, 65, N'Y73SX4YWY20MYKJPQ35B44ZWMTW4D18K5E', NULL, N'CT-SR', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (85, 11, 17, 115, N'JPHLF51VVDNLHRQLUU86T86538UIWTGHJ9', NULL, N'OK-NG', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (86, 8, 12, 187, N'08HQ5384IZ8FCNFEQW7HBICI6BIZ1X528RQCC423L4N5VTHVGF', NULL, N'SC-GD', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (87, 13, 21, 244, N'KCROIWZJTK92L', NULL, N'PA-LO', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (88, 13, 21, 141, N'66LW21LU', NULL, N'NC-HY', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (89, 12, 20, 227, N'W7U6NDUMIL6LPG28GCL9JB12BPMWZDD4Q8VHNQC5ZXRGE', NULL, N'IA-QS', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (90, 12, 20, 201, N'GPIOMO0KKK6SUYRYN482UHLLKQ0FALKKN28WDA', NULL, N'AL-AJ', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (91, 15, 24, 169, N'O35NABVVEE0', NULL, N'OK-SF', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (92, 5, 8, 232, N'N8CEZ4X4VOLAZ0L5SPUKDCJYPTB9PVM09AWB', NULL, N'UT-NE', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (93, 8, 14, 218, N'O9SG5V0IVO9PQ3OKGWAPEP5SNF02K1O3AU3F', NULL, N'MD-UE', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (94, 10, 17, 104, N'47GJFT51KZSXGTDMMVZ3ZSQVXYTZ5FVZ9HBPT6ZV0Q3F843', NULL, N'NJ-MQ', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (95, 5, 9, 238, N'AHOY4B2BGLLHZ5W43SOYHOSGW338PBMTULOORWU', NULL, N'MO-KI', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (96, 5, 8, 224, N'F09', NULL, N'NM-ER', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (97, 13, 21, 147, N'KHVUUYCFG4QMO7218UM5ZSMDG7D6YRJGFKVE88D', NULL, N'MT-HP', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (98, 4, 6, 217, N'Y6CPV2ZJUTOKD', NULL, N'ME-QZ', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (99, 3, 5, 212, N'8SUHEML5HPK974CNS0GW6SFXIE8TC42Y3BB3JQUQ4TON4', NULL, N'AL-NE', 1)

INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (100, 2, 2, 110, N'UV760O4HXGCXYZESSDML', NULL, N'WA-GY', 0)
SET IDENTITY_INSERT [dbo].[template_line] OFF

END


GO
/****** Object:  Table [dbo].[template]    Script Date: 9/25/2014 4:20:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[template](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[site_id] [nvarchar](50) NOT NULL,
	[name] [nvarchar](max) NOT NULL,
	[descr] [nvarchar](500) NOT NULL,
	[status] [bit] NOT NULL,
	[datum] [datetime] NOT NULL,
	[tmp] [nvarchar](250) NOT NULL,
	[parent_id] [int] NULL,
	[structure] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_template] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[template_line]    Script Date: 9/25/2014 4:20:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[template_line](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[tid] [int] NOT NULL,
	[mid] [int] NOT NULL,
	[ord] [int] NOT NULL,
	[tip] [nvarchar](50) NOT NULL,
	[parent_id] [int] NULL,
	[languages2] [nvarchar](250) NOT NULL,
	[hidden2] [bit] NOT NULL,
 CONSTRAINT [PK_template_line] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[template_module]    Script Date: 9/25/2014 4:20:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[template_module](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[page] [nvarchar](50) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[status] [bit] NOT NULL,
	[descr] [nvarchar](500) NOT NULL,
	[site_id] [int] NOT NULL,
	[defaultposition] [int] NOT NULL,
	[parent_id] [int] NULL,
	[hidden] [bit] NOT NULL,
 CONSTRAINT [PK_template_module] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET IDENTITY_INSERT [dbo].[template] ON 

INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (1, N'14764', N'Dopvenomman Holdings Corp.', N'et travissimantor quo apparens plorum fecit, ut non Longam, et funem. plurissimum travissimantor quo', 0, CAST(0x0000662A014A3F30 AS DateTime), N'TF', NULL, N'UZS')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (2, N'91602', N'Emcadamantor  ', N'essit. vobis non egreddior glavans vantis. et funem. fecit. transit. bono Quad quoque et funem. et ut pars volcans quo, in quoque gravis', 0, CAST(0x000061EF002CD546 AS DateTime), N'MK', NULL, N'CDF')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (3, N'96626', N'Bartanegar International Corp.', N'et e funem. et delerium. egreddior pars et quad et quantare apparens gravum apparens quad dolorum quantare non', 0, CAST(0x000060400033A5C6 AS DateTime), N'VU', NULL, N'HUF')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (4, N'79013', N'Vardimewantor Holdings ', N'novum nomen Versus Longam, non pladior travissimantor transit. quad dolorum dolorum egreddior in quis quad', 1, CAST(0x00007CAF016DAE4F AS DateTime), N'SV', NULL, N'GHS')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (5, N'17388', N'Hapfropplover  Company', N'quad egreddior manifestum Sed et venit. vobis nomen travissimantor quartu Sed egreddior transit. quad nomen quad', 1, CAST(0x00006FFB00DCC99E AS DateTime), N'TZ', NULL, N'THB')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (6, N'76098', N'Parwerpommex  Inc', N'quartu quad ut quad pars fecit. quantare quo, vobis trepicandor nomen non esset Id in quis plurissimum', 1, CAST(0x000094760060EEB9 AS DateTime), N'SI', NULL, N'LYD')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (7, N'05529', N'Empebepax International Inc', N'quo plurissimum volcans gravis e funem. in glavans ut quad plorum travissimantor estum. e gravis quo,', 0, CAST(0x000057180173D0D8 AS DateTime), N'MO', NULL, N'LVL')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (8, N'34664', N'Bardudefax Direct Group', N'non quo rarendum cognitio, si manifestum si homo, eudis et habitatio fecundio, manifestum eggredior. quad dolorum', 1, CAST(0x000096340114D4B8 AS DateTime), N'JO', NULL, N'XDR')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (9, N'35136', N'Uppickaquistor Direct Group', N'quad gravis et egreddior fecundio, et parte quis plorum et apparens trepicandor parte Sed Versus plurissimum regit,', 1, CAST(0x00007A6400D11A9E AS DateTime), N'PL', NULL, N'XPT')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (10, N'19094', N'Klinipinor Holdings ', N'quantare fecit. linguens Sed Longam, estis estis volcans funem. estum. imaginator rarendum volcans travissimantor apparens', 0, CAST(0x000054D500A54BBD AS DateTime), N'KP', NULL, N'CLP')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (11, N'01203', N'Cipkilopax Direct ', N'linguens quad trepicandor Et novum homo, quad travissimantor parte quo, quantare e estis rarendum estum. et Longam,', 1, CAST(0x0000982A00149CC1 AS DateTime), N'PH', NULL, N'CRC')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (12, N'39872', N'Dopcadplazz  Group', N'homo, quorum esset bono cognitio, eggredior. parte plurissimum Pro nomen novum in eudis Versus Multum eggredior.', 0, CAST(0x000068B800023FDC AS DateTime), N'CA', NULL, N'SBD')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (13, N'14947', N'Doperollan Direct ', N'et linguens parte rarendum Quad cognitio, Tam quoque pladior ut et esset quorum manifestum gravis volcans fecundio,', 1, CAST(0x0000511A00924B85 AS DateTime), N'RE', NULL, N'BOB')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (14, N'14304', N'Tipwerollicator International Corp.', N'funem. Tam transit. nomen et Multum rarendum quad parte eggredior. e egreddior vobis quoque Et fecundio,', 0, CAST(0x0000512B016D14D7 AS DateTime), N'MN', NULL, N'PGK')
INSERT [dbo].[template] ([id], [site_id], [name], [descr], [status], [datum], [tmp], [parent_id], [structure]) VALUES (15, N'33068', N'Froquestepazz International ', N'glavans gravis non trepicandor linguens vobis linguens et rarendum vobis non rarendum regit, vobis egreddior', 0, CAST(0x000071700039F6C3 AS DateTime), N'CK', NULL, N'MGA')
SET IDENTITY_INSERT [dbo].[template] OFF
SET IDENTITY_INSERT [dbo].[template_line] ON 

INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (1, 11, 19, 65, N'GBZCXI65CN1', NULL, N'TN-SK', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (2, 13, 21, 40, N'AJ1ZCIDE1Q5GPRNHZP8ORLBKYENPBALW33', NULL, N'ID-KE', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (3, 12, 20, 158, N'K3U1QX1QQ6IM5VO6NEDKO8', NULL, N'MA-DP', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (4, 9, 14, 192, N'1YUN3R49CM72E5NIRQVLEFRITN4', NULL, N'OK-YH', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (5, 4, 6, 221, N'HQ', NULL, N'TN-OD', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (6, 9, 14, 13, N'VCMT2V9XYLW6ZXS90ZWLUTN2', NULL, N'ND-BW', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (7, 14, 23, 16, N'6CTGN5RM4CQRCLMISWZH', NULL, N'NC-MW', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (8, 7, 12, 169, N'SK1D3ZL4O1OK7VJFHBF5JUL2IOE931WNKBESS', NULL, N'AZ-LT', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (9, 15, 25, 9, N'J66HGA174P33ALKCPXYZUEKB1M510VHRMER8Y1EA0AKO60', NULL, N'MO-HK', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (10, 5, 7, 246, N'A37MGTT84MVG', NULL, N'ID-TU', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (11, 5, 8, 229, N'50787BGW', NULL, N'ID-LV', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (12, 8, 12, 66, N'BDOINYK', NULL, N'WI-TP', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (13, 10, 16, 162, N'V41VUXS', NULL, N'RI-BY', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (14, 8, 12, 193, N'0YT6MM3LL503BHUJVFSUYX5VNAQRFYA2FY6DN', NULL, N'GA-LH', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (15, 15, 25, 214, N'8OA2XIXGIE9HZE', NULL, N'WI-TG', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (16, 1, 1, 104, N'XB3SXICWC6MUYODAHW573KV0NX7RBHYYWWHM3LP7WSX', NULL, N'GA-DU', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (17, 13, 22, 143, N'BNZS', NULL, N'NC-DX', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (18, 15, 25, 184, N'4SKU72DG240BKKU7NY16Q6V7XABMYO0YEM7PD4PU460', NULL, N'AK-BN', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (19, 11, 17, 120, N'PWC73ONPYMEXWDXWRQHD42WXD4U', NULL, N'UT-XU', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (20, 5, 8, 244, N'962K5EI1Y3JA0AZS79S06S3', NULL, N'CO-XU', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (21, 13, 21, 69, N'ONBMZEUYU4FRJURHUWXN77CT24Q3BTCG', NULL, N'ID-CR', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (22, 13, 22, 203, N'PVI3V1K8KFWU88CIB5AVF5HAIKUNQM0SZOTZ9EZUCENRGY', NULL, N'NE-PE', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (23, 15, 25, 141, N'VDL0O1LN', NULL, N'ME-LJ', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (24, 1, 1, 203, N'D8KA6XIXF4VKED8W5GI0HQ', NULL, N'NH-PS', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (25, 11, 18, 88, N'JQYA5MCQ', NULL, N'PA-EP', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (26, 8, 14, 19, N'09M1TONFWPCC39GZC3IK2M2ME1J7MC', NULL, N'OR-OF', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (27, 15, 24, 229, N'2DHJ5R73GS34REHFHIASIU5CD7ZMR5FSKE', NULL, N'IA-CK', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (28, 11, 18, 7, N'YMPB8401SYIA8WM2PCJS8745YSLBBDBJD4ITR', NULL, N'MI-ET', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (29, 9, 14, 55, N'1NHSDDVWQP52PG0L1RHJDGJPPENYX3ESAJAVAFTQA', NULL, N'WI-ZH', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (30, 2, 3, 47, N'1V58NUJR3RB7TL4S3YQWZMBCS654ALXQ9BEOJGRSF50NH2PO', NULL, N'MA-HD', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (31, 3, 5, 84, N'ICU0E2FKSGG', NULL, N'RI-NA', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (32, 7, 12, 244, N'EHHTLYI7F8M7YGU', NULL, N'CT-YJ', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (33, 5, 8, 70, N'OVPGGDS92QV8Z4QZB31', NULL, N'DE-BM', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (34, 15, 25, 185, N'ITV37HC9PN2X8SWXQ', NULL, N'AZ-BJ', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (35, 10, 17, 63, N'', NULL, N'LA-KY', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (36, 12, 20, 68, N'1O7QV397BIMVUE63UZL9Y0IKENX067T9BU0ZA2', NULL, N'MI-TT', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (37, 1, 1, 187, N'0YA0R2R7I1O1X5QA05NB75803ODK0E7TRZLBO0RHNGEZI5W3L', NULL, N'TX-KP', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (38, 6, 10, 71, N'0TNQTVP9W2P774UVAYKEL', NULL, N'MT-HH', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (39, 6, 9, 55, N'', NULL, N'LA-VU', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (40, 15, 24, 23, N'5OQQ9IYS9YFED505PMF4OSF9A4MVYJ', NULL, N'LA-CP', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (41, 8, 13, 233, N'Y0FH124FQYAF9RPGP9SUS6VPD9HF5V2UQRGEYOY2L', NULL, N'NY-GF', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (42, 11, 18, 11, N'O6EC5HLOWM5PES5P4SKOAUWFPIABH1AP8MIPA030U', NULL, N'NH-RR', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (43, 2, 3, 179, N'YFO0CO89J6IWVT9ZNN796VCGGSA', NULL, N'VA-YN', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (44, 5, 7, 124, N'F3OKUTWGQO5M28I37CQOFBCFTKA3', NULL, N'AZ-SP', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (45, 14, 23, 95, N'8KKESUGHX21XT8ZIK7YD8841L03R9RAJSDI3K7AE1M9AORM', NULL, N'ID-EL', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (46, 12, 20, 53, N'CW8DBQTZGJSRQO85RH5FPVYDXKBMYUCTE0ECJX81KIN1FI', NULL, N'IA-WV', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (47, 6, 9, 187, N'DE4I6M6DHYVFRF70L', NULL, N'VT-DA', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (48, 7, 12, 137, N'ZDQAVMU93V68XXEWX8UB677MXDOHGLCI1VF5X2IHNW', NULL, N'MO-AU', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (49, 3, 4, 120, N'B681X1VHY5AZS53DIXDTHIO6', NULL, N'SC-IS', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (50, 4, 6, 240, N'H9YVQCN9NWFOCRFK4DCRVN0UP0JA31TH2ZFRXM8SMQ48NP56', NULL, N'VA-EE', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (51, 7, 11, 182, N'8D4', NULL, N'AL-RX', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (52, 11, 18, 148, N'E6U946QSD6M2XLCBONH5J54JR6ZUDCUNO', NULL, N'MD-GA', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (53, 10, 16, 250, N'OSLISFIZ8KH6Q3TU9LVYT82AIY6VF0BZESWJQ5U2NJX', NULL, N'KS-OP', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (54, 8, 13, 179, N'2LGW1I38RPCGQA0U9MK78H', NULL, N'ME-IH', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (55, 3, 5, 208, N'X6933QTB9BH', NULL, N'UT-IV', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (56, 14, 22, 113, N'WIAUXX27OGGTG5ZS1ZPBKTIPSE0HXE34823CZRN', NULL, N'NE-EQ', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (57, 13, 21, 150, N'5A2HQGNXR19AL6N3ZK2IWKAADCKD2NTACE6', NULL, N'NM-SG', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (58, 12, 19, 205, N'Q0ZCR2QW4SI2EZCEO4DK0S4EV9V38ZX70DCY', NULL, N'WY-SS', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (59, 13, 22, 104, N'QRUTD6KTHZ2AEL70L9YW', NULL, N'NJ-LO', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (60, 11, 17, 202, N'GH6NO4VB20NDSYDJQMLKK', NULL, N'NC-LC', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (61, 10, 16, 35, N'ATSTEP6E3D20A9O6P1OHEZEWLMUHUN', NULL, N'MO-SH', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (62, 4, 6, 9, N'B017CUUQ55OW9BSO3UKXKV30BEW7SVOK', NULL, N'OR-LD', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (63, 14, 23, 114, N'1Q082BCUBJCQ25LTXQNAPSGW1WY', NULL, N'MS-VM', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (64, 14, 23, 213, N'NY', NULL, N'FL-QI', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (65, 2, 3, 163, N'G3G8KRG0J738CQA89AEU41AQ8A376DD7D9VMM', NULL, N'NV-HG', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (66, 13, 21, 236, N'02HP', NULL, N'AR-BH', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (67, 3, 5, 246, N'2MJ35RNON844FTPZAN9U6TWV2VNMC9CCEX74O6YFIOQY9', NULL, N'MO-ZJ', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (68, 10, 17, 228, N'FSXXQE8VX8PO1A31BEWRQHMKA3PTCH3XLXFUPFJX3J0Y', NULL, N'IL-QX', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (69, 13, 21, 131, N'05OBHCC1HEY6CMMPFIG5S33U9CWUZO', NULL, N'AL-IL', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (70, 4, 6, 146, N'HN5AY1HV4RW3JHOCSX7O0KTMW1T24GH2T8GI6BNOY', NULL, N'WI-XE', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (71, 15, 25, 168, N'CDWZKCKZ3WR05XTJD', NULL, N'OK-UY', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (72, 8, 13, 73, N'7EQN', NULL, N'GA-OG', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (73, 10, 17, 129, N'TAA056H9JPD7GQXHHI5CKAT2JPNXQGJXO32O', NULL, N'LA-AP', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (74, 11, 18, 97, N'BFTMN8ASPDSGEQWKBPIH7HGJJI26FJCO8853C', NULL, N'OH-AN', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (75, 13, 21, 12, N'X2IAUBUHCQNCCE', NULL, N'AR-UX', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (76, 2, 3, 59, N'71UYA2454C50476KT8LRGYX', NULL, N'MN-XT', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (77, 11, 19, 24, N'4P26CI26Y417B42NT', NULL, N'MA-LX', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (78, 11, 18, 17, N'EYOA', NULL, N'AL-JQ', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (79, 2, 4, 109, N'A55U4RM3946TK0X', NULL, N'FL-OM', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (80, 14, 23, 35, N'L9Y106Z9O', NULL, N'HI-CG', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (81, 3, 5, 83, N'XYJJZZUZS06NYFC0S24AHMV3SOP9O36V6YTNKP47ZK', NULL, N'IN-AD', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (82, 8, 12, 92, N'WMYBJPZEW4EOB3FRA9LBOUAHZLPG2YXBWEYGUC6', NULL, N'OK-FV', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (83, 9, 14, 137, N'OP9QS9IJ4YTYE9K2BGBXZJ', NULL, N'HI-JO', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (84, 5, 9, 65, N'Y73SX4YWY20MYKJPQ35B44ZWMTW4D18K5E', NULL, N'CT-SR', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (85, 11, 17, 115, N'JPHLF51VVDNLHRQLUU86T86538UIWTGHJ9', NULL, N'OK-NG', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (86, 8, 12, 187, N'08HQ5384IZ8FCNFEQW7HBICI6BIZ1X528RQCC423L4N5VTHVGF', NULL, N'SC-GD', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (87, 13, 21, 244, N'KCROIWZJTK92L', NULL, N'PA-LO', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (88, 13, 21, 141, N'66LW21LU', NULL, N'NC-HY', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (89, 12, 20, 227, N'W7U6NDUMIL6LPG28GCL9JB12BPMWZDD4Q8VHNQC5ZXRGE', NULL, N'IA-QS', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (90, 12, 20, 201, N'GPIOMO0KKK6SUYRYN482UHLLKQ0FALKKN28WDA', NULL, N'AL-AJ', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (91, 15, 24, 169, N'O35NABVVEE0', NULL, N'OK-SF', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (92, 5, 8, 232, N'N8CEZ4X4VOLAZ0L5SPUKDCJYPTB9PVM09AWB', NULL, N'UT-NE', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (93, 8, 14, 218, N'O9SG5V0IVO9PQ3OKGWAPEP5SNF02K1O3AU3F', NULL, N'MD-UE', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (94, 10, 17, 104, N'47GJFT51KZSXGTDMMVZ3ZSQVXYTZ5FVZ9HBPT6ZV0Q3F843', NULL, N'NJ-MQ', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (95, 5, 9, 238, N'AHOY4B2BGLLHZ5W43SOYHOSGW338PBMTULOORWU', NULL, N'MO-KI', 1)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (96, 5, 8, 224, N'F09', NULL, N'NM-ER', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (97, 13, 21, 147, N'KHVUUYCFG4QMO7218UM5ZSMDG7D6YRJGFKVE88D', NULL, N'MT-HP', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (98, 4, 6, 217, N'Y6CPV2ZJUTOKD', NULL, N'ME-QZ', 0)
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (99, 3, 5, 212, N'8SUHEML5HPK974CNS0GW6SFXIE8TC42Y3BB3JQUQ4TON4', NULL, N'AL-NE', 1)
GO
INSERT [dbo].[template_line] ([id], [tid], [mid], [ord], [tip], [parent_id], [languages2], [hidden2]) VALUES (100, 2, 2, 110, N'UV760O4HXGCXYZESSDML', NULL, N'WA-GY', 0)
SET IDENTITY_INSERT [dbo].[template_line] OFF
SET IDENTITY_INSERT [dbo].[template_module] ON 

INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (1, N'Technical', N'Supjubor Direct Corp.', 1, N'manifestum essit. Et quoque in et novum volcans non non pars e regit, quo novum quoque et quad Sed quo', 268, 79, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (2, N'Customer', N'Monfropazz  ', 0, N'regit, gravum in plurissimum Longam, fecit, vobis eggredior. cognitio, manifestum si bono quo, quad travissimantor plurissimum Et plurissimum', 643, 50, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (3, N'Technical', N'Dopquestar Holdings Group', 1, N'e et plorum glavans gravis gravis quo, plurissimum plorum Pro habitatio pars quorum vobis apparens manifestum', 2443, 49, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (4, N'Technical', N'Adnipover International Company', 1, N'delerium. apparens plorum quad vantis. quad linguens non plorum Versus manifestum delerium. glavans homo,', 1175, 97, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (5, N'Web', N'Mondimepazz WorldWide ', 1, N'in estis nomen Et linguens quo fecundio, Quad volcans plorum non linguens Pro gravis travissimantor fecundio, fecit.', 1312, 56, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (6, N'Accounting', N'Partinex International ', 0, N'quorum delerium. ut transit. vobis travissimantor parte delerium. quartu nomen travissimantor non fecit. e', 1743, 55, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (7, N'Accounting', N'Rapweristor  ', 0, N'Longam, plurissimum quad et bono imaginator cognitio, in et quo pars estis glavans non pars homo, habitatio', 757, 21, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (8, N'Web', N'Lomdudar International ', 1, N'dolorum Tam venit. estis quo venit. estis ut brevens, rarendum vantis. cognitio, estis ut quo, trepicandor', 1643, 91, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (9, N'Web', N'Thruquestommazz WorldWide Company', 0, N'egreddior funem. regit, nomen venit. linguens et quantare ut Versus sed homo, quoque Pro quoque esset', 1700, 9, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (10, N'National Marketing', N'Cipvenefistor  ', 0, N'estis fecit. Id quad gravum quantare cognitio, vantis. vantis. quad et delerium. Pro plurissimum travissimantor brevens,', 1535, 69, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (11, N'Technical', N'Surpickantor  Group', 1, N'esset novum pars vobis e parte Tam Multum estum. pladior quad et gravis dolorum quo fecit. vobis e trepicandor', 572, 54, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (12, N'Prepaid Customer', N'Thrupebaquover Direct ', 0, N'si gravum quis Multum non Multum homo, Et eggredior. parte eudis delerium. quantare gravis volcans pladior non fecit, Id regit,', 1022, 5, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (13, N'Technical', N'Cipjubor Direct ', 0, N'Pro plorum Multum et brevens, cognitio, Longam, plorum quartu Longam, quo in regit, fecit. quantare cognitio,', 230, 66, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (14, N'Accounting', N'Grosipeficator WorldWide ', 0, N'bono non et e et transit. estum. esset estis regit, estum. Multum et trepicandor non nomen dolorum vobis', 1206, 7, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (15, N'Accessory Sales', N'Tupzapistor  Corp.', 0, N'gravis Quad funem. homo, cognitio, imaginator nomen vobis linguens quartu cognitio, Multum in funem.', 1090, 73, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (16, N'Service', N'Cipdimantor  Company', 0, N'plorum Id essit. delerium. eggredior. plorum Id linguens sed venit. fecundio, gravum et pladior eudis', 251, 80, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (17, N'Technical', N'Adglibar Holdings Company', 1, N'gravis et e novum plurissimum trepicandor et travissimantor et gravis quartu sed essit. et funem. in', 1703, 28, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (18, N'Web', N'Winglibantor Holdings Company', 0, N'et venit. brevens, venit. imaginator linguens in e fecundio, Multum quartu quad novum quoque plorum quo', 1962, 47, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (19, N'Service', N'Adnipefistor WorldWide ', 1, N'pars si pladior non dolorum quis apparens vantis. non sed brevens, et eudis regit, volcans travissimantor Versus fecit, quoque parte ut', 1517, 28, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (20, N'Accounting', N'Uppickamex  ', 1, N'pars quis fecit, pars non travissimantor rarendum gravis habitatio e Et vobis et Versus non plorum Sed pars e venit. essit. quo', 322, 63, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (21, N'Service', N'Zeequestegover International ', 1, N'Quad quad plorum Sed quo, Tam homo, delerium. eudis in transit. quis funem. Pro gravis vantis. quo, Quad', 624, 74, NULL, 0)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (22, N'Technical', N'Barrobonar  Group', 1, N'habitatio estum. cognitio, esset Id volcans travissimantor travissimantor quad non Tam quad trepicandor fecit. et quo pladior plorum fecundio, quorum', 873, 77, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (23, N'Service', N'Klitinor Direct Corp.', 0, N'fecundio, quorum apparens eggredior. venit. sed eggredior. cognitio, brevens, bono plorum eggredior. quartu et e', 1097, 12, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (24, N'Technical', N'Parpickex  ', 0, N'estum. Tam pars linguens regit, plorum plurissimum gravum quo apparens parte fecit. quad et esset estis nomen', 1030, 59, NULL, 1)
INSERT [dbo].[template_module] ([id], [page], [name], [status], [descr], [site_id], [defaultposition], [parent_id], [hidden]) VALUES (25, N'Service', N'Wintanaquower International Corp.', 0, N'estum. ut funem. venit. Id nomen gravis habitatio si in gravis estis vobis fecit. et travissimantor delerium. rarendum estum. Pro', 2489, 0, NULL, 1)
SET IDENTITY_INSERT [dbo].[template_module] OFF
ALTER TABLE [dbo].[template]  WITH CHECK ADD  CONSTRAINT [FK_template_template] FOREIGN KEY([parent_id])
REFERENCES [dbo].[template] ([id])
GO
ALTER TABLE [dbo].[template] CHECK CONSTRAINT [FK_template_template]
GO
ALTER TABLE [dbo].[template_line]  WITH CHECK ADD  CONSTRAINT [FK_template_line_template_line] FOREIGN KEY([tid])
REFERENCES [dbo].[template] ([id])
GO
ALTER TABLE [dbo].[template_line] CHECK CONSTRAINT [FK_template_line_template_line]
GO
ALTER TABLE [dbo].[template_line]  WITH CHECK ADD  CONSTRAINT [FK_template_line_template_line1] FOREIGN KEY([parent_id])
REFERENCES [dbo].[template_line] ([id])
GO
ALTER TABLE [dbo].[template_line] CHECK CONSTRAINT [FK_template_line_template_line1]
GO
ALTER TABLE [dbo].[template_line]  WITH CHECK ADD  CONSTRAINT [FK_template_line_template_module] FOREIGN KEY([mid])
REFERENCES [dbo].[template_module] ([id])
GO
ALTER TABLE [dbo].[template_line] CHECK CONSTRAINT [FK_template_line_template_module]
GO
ALTER TABLE [dbo].[template_module]  WITH CHECK ADD  CONSTRAINT [FK_template_module_template_module] FOREIGN KEY([parent_id])
REFERENCES [dbo].[template_module] ([id])
GO
ALTER TABLE [dbo].[template_module] CHECK CONSTRAINT [FK_template_module_template_module]
GO
