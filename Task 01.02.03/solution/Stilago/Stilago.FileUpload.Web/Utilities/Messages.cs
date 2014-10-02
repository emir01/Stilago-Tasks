namespace Stilago.FileUpload.Web.Utilities
{
    /// <summary>
    /// Contains a centralized collection/registry of UI messages. 
    /// 
    /// These can be better stored and managed in resource files, but this would be good enough for now.
    /// </summary>
    public static class Messages
    {
        #region Upload Failed

        public static string UploadFailedShortMessage = "Ooops!";

        public static string UploadFailedLongMessage =
            "Oops! Something went wrong with the hamsters responsible for processing and storing your file! Please try again.";

        #endregion

        #region Upload Success

        public static string UploadSuccessShortMessage = "Great Success!";

        public static string UploadSuccessLongMessageTemplate = "Successfully saved file. Save this file number to get your file once we implement downloads: {0}!";

        #endregion
    }
}