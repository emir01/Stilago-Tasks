using Stilago.FileUpload.Web.Utilities;

namespace Stilago.FileUpload.Web.Models
{
    /// <summary>
    /// View model for the result page for file uploads.
    /// </summary>
    public class UploadFileResultRenderViewModel
    {
        #region Properties

        public bool UploadStatus { get; set; }

        public string UploadShortMessage { get; set; }

        public string Message { get; set; }

        #endregion

        #region Ctor

        public UploadFileResultRenderViewModel()
        {
            UploadStatus = false;

            // default error message
            UploadShortMessage = Messages.UploadFailedShortMessage;

            // default error message
            Message = Messages.UploadFailedLongMessage;
        }

        #endregion
    }
}