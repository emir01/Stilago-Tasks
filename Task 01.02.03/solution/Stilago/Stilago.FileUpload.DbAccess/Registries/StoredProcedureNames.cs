namespace Stilago.FileUpload.DbAccess.Registries
{
    public static  class StoredProcedureNames
    {
        /// <summary>
        /// Stored procedure for uploading and saving the files to the database.
        /// 
        /// Stored procedure returns the id of the newly stored file
        /// </summary>
        public static string UploadFileToDb = "UploadFileToDb";
    }
}
