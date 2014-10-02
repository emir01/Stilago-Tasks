using System;
using System.Collections.Generic;
using System.Linq;
using Stilago.TableRender.Web.Models;
using Stilago.TableRender.Web.Utilities.Interface;
using WebGrease.Css.Ast;

namespace Stilago.TableRender.Web.Utilities
{
    public class RandomTableDataGenerator : IRandomTableDataGenerator
    {
        #region Properties

        private readonly Random _rand;

        // Can read/set from configuration if you want it more configurable and generic, but again, lets not bother
        private const int MinRandValue = 1;
        private const int MaxRandValue = 1000;

        #endregion

        #region Construction

        public RandomTableDataGenerator()
        {
            _rand = new Random();
        }

        #endregion

        #region Interface

        /// <summary>
        /// Generate a render model for the random table view.
        /// 
        /// Can specify the number of rows to generate.
        /// </summary>
        /// <param name="numberOfRows"></param>
        /// <returns></returns>
        public RandomTableModel GetRandomTable(int numberOfRows)
        {
            var randomTableModel = new RandomTableModel();

            for (int i = 0; i < numberOfRows; i++)
            {
                var row = GetRandomTableRow(i + 1);

                row.FirstSumComponents = GetSumComponentsFromRows(randomTableModel.Rows, r => r.RandomNumber, row.RandomNumber);
                row.SecondSumComponents = GetSumComponentsFromRows(randomTableModel.Rows, r => r.FirstSumComponents.Sum(), row.FirstSumComponents.Sum());

                randomTableModel.Rows.Add(row);
            }

            return randomTableModel;
        }

        #endregion

        #region Private

        /// <summary>
        /// Construct the base Table Row
        /// </summary>
        /// <param name="rowOrder"></param>
        /// <returns></returns>
        private RandomTableRow GetRandomTableRow(int rowOrder)
        {
            return new RandomTableRow()
            {
                RowOrder = rowOrder,
                RandomNumber = _rand.Next(MinRandValue, MaxRandValue),
            };
        }

        /// <summary>
        /// Generate sum components based on the current list of generated Rows.
        /// 
        /// Currently generated rows are processed based on a user provided filter for currentRowsSelection.
        /// 
        /// Provides a way to add additional sum components at the end, which in turn provides the final ( current row number or sum ) to be added.
        /// </summary>
        /// <param name="currentRows">The current collection of generated rows</param>
        /// <param name="currentRowsSelection">How the current generated rows will be processed for pulling sum components</param>
        /// <param name="additionalSumComponents">Any additional sum components for the current working row</param>
        /// <returns></returns>
        private List<int> GetSumComponentsFromRows(IEnumerable<RandomTableRow> currentRows, Func<RandomTableRow, int> currentRowsSelection, params int[] additionalSumComponents)
        {
            List<int> sumComponents = currentRows.Select(currentRowsSelection).ToList();
            sumComponents.AddRange(additionalSumComponents);
            return sumComponents;
        }

        #endregion
    }
}