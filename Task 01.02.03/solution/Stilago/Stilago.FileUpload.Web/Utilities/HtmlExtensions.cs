using System.Web.Mvc;

namespace Stilago.FileUpload.Web.Utilities
{
    /// <summary>
    /// Contains a collection of Html helper extensions
    /// </summary>
    public static  class HtmlExtensions
    {
        /// <summary>
        /// Determine between upload-success and upload-failed class names based on the state of the flag.
        /// 
        /// true:  success
        /// false: failed
        /// </summary>
        /// <param name="helper"></param>
        /// <param name="flag"></param>
        /// <returns></returns>
        public static string GetUploadClassForFlag(this HtmlHelper helper, bool flag)
        {
            if (flag)
            {
                return "upload-success";
            }
            else
            {
                return "upload-failed";
            }
        }
    }
}