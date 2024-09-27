using System.Collections.Generic;

namespace FrogTracker.Models
{
    public class ItemHistoryModel
    {
        public string ItemName { get; set; }
        public double? LastScrapeTime { get; set; }
        public ItemStatsModel ItemStats { get; set; }
        public IList<ItemHistoryRecordModel> History { get; set; }
        public int? SevenDayLowestPrice { get; set; }
        public int? SevenDayMedianPrice { get; set; }
        public int? ThirtyDayLowestPrice { get; set; }
        public int? ThirtyDayMedianPrice { get; set; }
        public int? NinetyDayLowestPrice { get; set; }
        public int? NinetyDayMedianPrice { get; set; }
        public int? OneYearLowestPrice { get; set; }
        public int? OneYearMedianPrice { get; set; }
        public int? LifetimeLowestPrice { get; set; }
        public int? LifetimeMedianPrice { get; set; }

        public ItemHistoryModel()
        {
            History = new List<ItemHistoryRecordModel>();
        }

        // inner classes

        public class ItemHistoryRecordModel
        {
            public string AuctionDate { get; set; }
            public int Price { get; set; }
            public string SellerName { get; set; }
            public bool IsForSaleNow { get; set; }
        }
    }
}
