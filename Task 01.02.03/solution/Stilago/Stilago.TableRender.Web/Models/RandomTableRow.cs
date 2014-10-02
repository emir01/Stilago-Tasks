using System.Collections.Generic;

namespace Stilago.TableRender.Web.Models
{
    public class RandomTableRow
    {
        public int RowOrder { get; set; }

        public int RandomNumber { get; set; }

        public List<int> FirstSumComponents { get; set; }

        public List<int> SecondSumComponents { get; set; }

        #region Ctor

        public RandomTableRow()
        {
            FirstSumComponents = new List<int>();
            SecondSumComponents =new List<int>();
        }

        #endregion
    }
}