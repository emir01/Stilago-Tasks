namespace Stilago.FileUpload.Domain.ResultObjects
{
    /// <summary>
    /// DTO object wrapping data action results.
    /// 
    /// Used in communication and passing messages between front and back tiers of an applicatoin.
    /// 
    /// Currently used to communicate between Repository tier and Front-End Tier.
    /// 
    /// This is a base implementation that can be used for communication purposes not carying any additional
    /// information
    /// </summary>
    public class DataActionResult
    {
        #region Properties

        public bool IsSuccess { get; set; }

        public string Message { get; set; }

        public bool IsException { get; set; }

        public string ExceptionMessage { get; set; }

        #endregion

        #region Ctor

        public DataActionResult()
        {
            IsSuccess = false;
            IsException = false;
        }

        #endregion
    }


    /// <summary>
    /// More advanced version of the DataActionResult that can actually pass around
    /// values and objects in case data actions need to return results.
    /// 
    /// In a way allows the interfaces for data action repositories to also define return types
    /// via the type parameter T
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public class ReturnDataActionResult<T> : DataActionResult
    {
        public T Data { get; set; }
    }
}
