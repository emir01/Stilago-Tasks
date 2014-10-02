using Stilago.TableRender.Web.Models;

namespace Stilago.TableRender.Web.Utilities.Interface
{
    public interface IRandomTableDataGenerator
    {
        /// <summary>
        /// Generate a render model for the random table view.
        /// 
        /// Can specify the number of rows to generate.
        /// </summary>
        /// <param name="numberOfRows"></param>
        /// <returns></returns>
        RandomTableModel GetRandomTable(int numberOfRows);
    }
}