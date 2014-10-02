using System;
using System.Data;
using System.Data.SqlClient;
using Stilago.FileUpload.DbAccess.ConnectionFactories;
using Stilago.FileUpload.DbAccess.Registries;
using Stilago.FileUpload.DbAccess.Repositories.Interface;
using Stilago.FileUpload.Domain.Entities;
using Stilago.FileUpload.Domain.ResultObjects;

namespace Stilago.FileUpload.DbAccess.Repositories
{
    /// <summary>
    /// The implementation of the IDbFileRepository interface. 
    /// 
    /// Performs additional exception checking and BL checks as 
    /// we have removed middle tier from the app on purpose for time and simplicity sakes.
    /// 
    /// On other ocasions data access code does not do the checks bellow and is a simple
    /// mostly CRUD layer without any logic.
    /// </summary>
    public class DbStoredProcedureFileRepository : IDbFileRepository
    {
        #region Properties

        private readonly SqlObjectsFactory _sqlObjectsFactory;

        public DbStoredProcedureFileRepository()
        {
            _sqlObjectsFactory = new SqlObjectsFactory();
        }

        #endregion

        #region Ctor

        #endregion


        #region Interface

        #endregion

        public ReturnDataActionResult<int> StoreFile(DbBackupFile file)
        {
            var result = new ReturnDataActionResult<int>();
            
            try
            {
                using (var con = _sqlObjectsFactory.GetBaseSqlConnection())
                {
                    con.Open();
                    var command = _sqlObjectsFactory.GetStoredProcedureCommand(con, StoredProcedureNames.UploadFileToDb);

                    // add the parameters for the command
                    // here we can do something with reflection and possibly attribute decorations
                    // on DbBackupFile to auto pull and configure parameters

                    var fileNameParam = command.Parameters.Add("@fileName", SqlDbType.NVarChar, 500);
                    fileNameParam.Value = file.FileName;

                    var contentTypeParam = command.Parameters.Add("@contentType", SqlDbType.NVarChar, 500);
                    contentTypeParam.Value = file.ContenType;

                    var contentLengthParam = command.Parameters.Add("@contentLength", SqlDbType.Int);
                    contentLengthParam.Value = file.ContentLength;

                    var dataParam = command.Parameters.Add("@data", SqlDbType.VarBinary);
                    dataParam.Value = file.Data;

                    // add the output param
                    var outputPar = command.Parameters.Add("@fileid", SqlDbType.Int);
                    outputPar.Direction = ParameterDirection.Output;

                    // Execute the command
                    command.ExecuteNonQuery();

                    var insertedIntegerValue = outputPar.Value;

                    result.IsSuccess = true;
                    result.Data = (int)insertedIntegerValue;

                    con.Close();
                }
            }
            catch (Exception ex)
            {
                result.IsException = true;
                result.ExceptionMessage = ex.Message;
            }

            return result;
        }
    }
}