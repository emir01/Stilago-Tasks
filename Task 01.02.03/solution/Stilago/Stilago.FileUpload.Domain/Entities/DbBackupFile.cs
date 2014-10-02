using System;

namespace Stilago.FileUpload.Domain.Entities
{
    /// <summary>
    /// The main entity definition for the DbBackup application.
    /// </summary>
    public class DbBackupFile
    {
        #region Properties

        public Int64 ContentLength { get; set; }

        public string ContenType { get; set; }

        public string FileName { get; set; }

        public byte[] Data { get; set; }

        #endregion

        #region Ctor

        public DbBackupFile(int contentLength)
        {
            Data = new byte[contentLength];
        }

        #endregion
    }

}