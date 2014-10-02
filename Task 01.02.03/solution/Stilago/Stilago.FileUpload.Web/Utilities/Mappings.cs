using System;
using System.IO;
using System.Web;
using Stilago.FileUpload.Domain.Entities;

namespace Stilago.FileUpload.Web.Utilities
{
    /// <summary>
    /// Contains object mappings between front facing objects and DTOs for communication
    /// with business logic/repositories.
    /// </summary>
    public class Mappings
    {
        public static DbBackupFile MapHttpPostedFileBaseToDbBackupFile(HttpPostedFileBase file)
        {
            try
            {
                var dbBackupFile = new DbBackupFile(file.ContentLength)
                {
                    FileName = file.FileName,
                    ContenType = file.ContentType,
                    ContentLength = file.ContentLength,
                };

                // dispose of stream after reading into the dbBackupFile object
                using (Stream inputStream = file.InputStream)
                {
                    inputStream.Read(dbBackupFile.Data, 0, file.ContentLength);
                }

                return dbBackupFile;
            }
            catch (Exception ex)
            {
                // if something goes wrong with the mapping/reading of binary data
                // return a null object which allows controller to return correct response message
                return null;
            }
        }
    }
}