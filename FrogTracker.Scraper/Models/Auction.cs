using System;
using System.Collections.Generic;
using System.Text;

namespace FrogTracker.Scraper.Models
{
    public class Auction
    {
        public DateTime AuctionDate { get; set; }
        public string ItemName { get; set; }
        public int Price { get; set; }
        public string SellerName { get; set; }
    }
}
