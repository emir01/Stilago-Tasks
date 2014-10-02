using Stilago.FileUpload.Domain.Entities;
using Stilago.FileUpload.Domain.ResultObjects;

namespace Stilago.FileUpload.DbAccess.Repositories.Interface
{
    /// <summary>
    /// Define the base functionality for storing DbBackup Files
    /// </summary>
    public interface IDbFileRepository
    {
        /// <summary>
        /// Store the Db Backup file and return a Data Action Result.
        /// 
        /// Note: This should also do some additional Exception checking as we do not have
        /// a middle tier implementation for this application (on purpose). 
        /// 
        /// That is why the return type is ReturnDataActionResult which wraps around
        /// the integer id of the inserted file.
        /// 
        /// Data is populated if IsSuccess is true/otherwise 0.
        /// </summary>
        /// <param name="file">The file to be stored</param>
        /// <returns></returns>
        ReturnDataActionResult<int> StoreFile(DbBackupFile file);
    }
}
