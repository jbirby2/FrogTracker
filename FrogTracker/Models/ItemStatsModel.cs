﻿using System.Collections.Generic;

namespace FrogTracker.Models
{
    public class ItemStatsModel
    {
        public string ItemName { get; set; }
        public IList<ItemStatsRecordModel> Stats { get; set; }

        public ItemStatsModel()
        {
            Stats = new List<ItemStatsRecordModel>();
        }

        // inner class

        public class ItemStatsRecordModel
        {
            public string RawLine { get; set; }
            public string ParsedStatName { get; set; }
            public string ParsedStatValue { get; set; }
        }
    }
}
