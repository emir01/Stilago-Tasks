using System.Web.Mvc;
using Stilago.TableRender.Web.Utilities;
using Stilago.TableRender.Web.Utilities.Interface;

namespace Stilago.TableRender.Web.Controllers
{
    public class HomeController : Controller
    {
        #region Props

        private readonly IRandomTableDataGenerator _randomTableDataGenerator;

        #endregion

        #region Ctor

        public HomeController()
        {
            // Or DI Inject, but lets not bother
            _randomTableDataGenerator = new RandomTableDataGenerator();
        }

        #endregion

        public ActionResult Index()
        {
            var model = _randomTableDataGenerator.GetRandomTable(10);

            return View(model);
        }
    }
}