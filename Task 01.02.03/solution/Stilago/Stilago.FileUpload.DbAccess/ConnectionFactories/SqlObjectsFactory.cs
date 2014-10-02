using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace Stilago.FileUpload.DbAccess.ConnectionFactories
{
    /// <summary>
    /// Provides a centralized place for creating sql objects. 
    /// </summary>
    public class SqlObjectsFactory
    {
        #region Connection Factory Configuration

        #endregion

        #region Connections

        /// <summary>
        /// Return the base sql connection for the DbBackup local database.
        /// 
        /// Connection is pulled from the configuration manager.
        /// </summary>
        /// <returns></returns>
        public SqlConnection GetBaseSqlConnection()
        {
            var conString = ConfigurationManager.ConnectionStrings["DbBackupConnectionString"];

            if (conString == null)
            {
                throw new Exception("Could not find Connection String");
            }
            else
            {
                return new SqlConnection(conString.ConnectionString);
            }
        }

        #endregion

        #region Commands

        /// <summary>
        /// Return a sql command to execute a given stored procedure.
        /// </summary>
        /// <param name="con"></param>
        /// <param name="procedureName"></param>
        /// <returns></returns>
        public SqlCommand GetStoredProcedureCommand(SqlConnection con, string procedureName)
        {
            var command = new SqlCommand
            {
                CommandType = CommandType.StoredProcedure,
                Connection = con,
                CommandText = procedureName
            };

            return command;
        }

        #endregion
    }
}
