using System.Collections.Generic;

namespace Stilago.TableRender.Web.Models
{
    public class RandomTableModel
    {
        #region Ctor

        public RandomTableModel()
        {
            Rows = new List<RandomTableRow>();
        }

        #endregion

        public List<RandomTableRow> Rows { get; set; }
    }
}