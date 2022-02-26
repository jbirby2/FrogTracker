using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace FrogTracker.Models
{
    public class SearchResultModel
    {
        public string SearchString { get; set; }
        public IList<string> ItemNames { get; set; }
        public IList<ItemStatsModel> ItemStats { get; set; }

        public SearchResultModel()
        {
            ItemNames = new List<string>();
            ItemStats = new List<ItemStatsModel>();
        }
    }
}
