using System.IO;
using System.Web;
using System.Web.Mvc;
using Stilago.FileUpload.DbAccess.Repositories;
using Stilago.FileUpload.DbAccess.Repositories.Interface;
using Stilago.FileUpload.Domain.Entities;
using Stilago.FileUpload.Web.Models;
using Stilago.FileUpload.Web.Utilities;

namespace Stilago.FileUpload.Web.Controllers
{
    public class HomeController : Controller
    {
        #region Properties

        private readonly IDbFileRepository _dbFileRepository;

        #endregion

        #region Ctor

        public HomeController()
        {
            // Use IoC Container (SM) but for simplicity and time 
            _dbFileRepository = new DbStoredProcedureFileRepository();
        }

        #endregion

        #region Actions

        /// <summary>
        /// GET: Render the file upload page.
        /// </summary>
        /// <returns></returns>
        public ActionResult Index()
        {
            return View();
        }

        /// <summary>
        /// GET: Render the file upload page.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        public ActionResult Upload(HttpPostedFileBase file)
        {
            // map HttpPostedFi
            var domainFile = Mappings.MapHttpPostedFileBaseToDbBackupFile(file);

            var uploadResultRenderModel = new UploadFileResultRenderViewModel();

            if (domainFile == null)
            {
                return View(uploadResultRenderModel);
            }

            var saveResult = _dbFileRepository.StoreFile(domainFile);

            if (saveResult.IsSuccess)
            {
                uploadResultRenderModel.UploadStatus = true;

                // get the id of the uploaded file
                var uploadedFileId = saveResult.Data;

                uploadResultRenderModel.Message = string.Format(Messages.UploadSuccessLongMessageTemplate, uploadedFileId);
                uploadResultRenderModel.UploadShortMessage = Messages.UploadSuccessShortMessage;

                return View(uploadResultRenderModel);
            }
            else
            {
                // just return the default failed render model
                return View(uploadResultRenderModel);
            }

            return View();
        }

        #endregion
    }
}