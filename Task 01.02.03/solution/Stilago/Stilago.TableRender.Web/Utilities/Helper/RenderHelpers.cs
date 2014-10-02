using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web.Mvc;

namespace Stilago.TableRender.Web.Utilities.Helper
{
    public static class RenderHelpers
    {
        /// <summary>
        /// Static rendering utility for the sumation strings based ona  list
        /// of sum components.
        ///  </summary>
        /// <param name="helper"></param>
        /// <param name="sumComponents"></param>
        /// <returns></returns>
        public static string GenerateSumationString(this HtmlHelper helper, List<int> sumComponents)
        {
            var stringBuilder = new StringBuilder();

            for (int i = 0; i < sumComponents.Count; i++)
            {
                var sumComponent = sumComponents[i];
                stringBuilder.Append(sumComponent.ToString(CultureInfo.InvariantCulture));

                if (i < sumComponents.Count - 1)
                {
                    stringBuilder.Append("+");
                }
                else
                {
                    stringBuilder.Append("=").Append(sumComponents.Sum());
                }
            }

            return stringBuilder.ToString();
        }
    }
}