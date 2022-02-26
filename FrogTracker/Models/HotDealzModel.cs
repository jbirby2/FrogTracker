using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace FrogTracker.Models
{
    public class HotDealzModel
    {
        public IList<HotDealzRecordModel> Dealz { get; set; }
        public IList<ItemStatsModel> ItemStats { get; set; }

        public HotDealzModel()
        {
            Dealz = new List<HotDealzRecordModel>();
            ItemStats = new List<ItemStatsModel>();
        }


        // inner classes

        public class HotDealzRecordModel
        {
            public string ItemName { get; set; }
            public int Price { get; set; }
            public string SellerName { get; set; }
            public int LowestPrice { get; set; }
            public int PercentAboveLowest { get; set; }
            public int AmountAboveLowest { get; set; }
            public int MedianPrice { get; set; }
            public int PercentBelowMedian { get; set; }
            public int AmountBelowMedian { get; set; }
        }
    }
}
