using System.ServiceModel.Syndication;
using System.Web.Mvc;
using System.Xml;

namespace Stilago.RssFeed.Web.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return View();
        }
    }
}