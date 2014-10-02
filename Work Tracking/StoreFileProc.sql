CREATE PROCEDURE [dbo].UploadFileToDb
	 @fileName nvarchar(500)
	,@contentType nvarchar(500)
	,@contentLength int
	,@data varbinary(MAX)
	,@fileid int OUTPUT
AS
	INSERT INTO DbBackupFile
	(
	     FileName
		,ContentType
		,ContentLength
		,Data
	)
	VALUES
	(
		 @fileName
		,@contentType
		,@contentLength
		,@data
	);

	SELECT @fileid =  SCOPE_IDENTITY();

RETURN
