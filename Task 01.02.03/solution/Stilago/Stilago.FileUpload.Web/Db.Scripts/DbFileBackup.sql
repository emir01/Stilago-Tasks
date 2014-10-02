CREATE TABLE [dbo].[Table]
(
	[Id] INT NOT NULL PRIMARY KEY, 
    [FileName] NVARCHAR(500) NULL, 
    [ContentType] NVARCHAR(500) NULL, 
    [ContentLength] INT NULL, 
    [Data] VARBINARY(MAX) NULL
)
