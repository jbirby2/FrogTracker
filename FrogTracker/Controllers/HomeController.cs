using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using FrogTracker.Models;
using Microsoft.Extensions.Configuration;
using MySql.Data.MySqlClient;
using System.Data;

namespace FrogTracker.Controllers
{
    public class HomeController : Controller
    {
        private IConfiguration config;

        public HomeController(IConfiguration configuration)
        {
            config = configuration;
        }

        public IActionResult Index(string item = null)
        {
            return View(new IndexModel() { ItemName = item });
        }

        public IActionResult Search(string searchString)
        {
            var model = new SearchResultModel() { SearchString = searchString };

            if (searchString != null && searchString.Trim().Length >= 3)
            {
                using (var sqlConn = new MySqlConnection(config["ConnectionString"]))
                using (var sqlCmd = new MySqlCommand("auction_select_item_names", sqlConn))
                using (var adapter = new MySqlDataAdapter(sqlCmd))
                using (var dataSet = new DataSet())
                {
                    sqlCmd.CommandType = CommandType.StoredProcedure;
                    sqlCmd.Parameters.AddWithValue("p_search_string", searchString);
                    adapter.Fill(dataSet);

                    foreach (DataRow row in dataSet.Tables[0].Rows)
                    {
                        string itemName = (string)row["item_name"];

                        model.ItemNames.Add(itemName);

                        // Run a separate query to fetch the stats rows for each unique item name in the results
                        if (!model.ItemStats.Any(itemModel => itemModel.ItemName == itemName))
                        {
                            var itemStatsModel = getItemStatsModel(sqlConn, itemName);
                            if (itemStatsModel != null)
                                model.ItemStats.Add(itemStatsModel);
                        }
                    }
                }
            }

            return Json(model);
        }

        public IActionResult ItemHistory(string itemName)
        {
            var model = new ItemHistoryModel();

            using (var sqlConn = new MySqlConnection(config["ConnectionString"]))
            {
                // Set model.LastScrapeTime
                using (var sqlCmd = new MySqlCommand("scrape_select_most_recent", sqlConn))
                using (var adapter = new MySqlDataAdapter(sqlCmd))
                using (var dataSet = new DataSet())
                {
                    sqlCmd.CommandType = CommandType.StoredProcedure;
                    adapter.Fill(dataSet);

                    if (dataSet.Tables[0].Rows.Count > 0)
                        model.LastScrapeTime = (((DateTime)dataSet.Tables[0].Rows[0]["scrape_time"]) - DateTime.UnixEpoch).TotalMilliseconds;
                    else
                        model.LastScrapeTime = null;
                }

                // Build model.History
                using (var sqlCmd = new MySqlCommand("auction_select_by_item_name", sqlConn))
                using (var adapter = new MySqlDataAdapter(sqlCmd))
                using (var dataSet = new DataSet())
                {
                    sqlCmd.CommandType = CommandType.StoredProcedure;
                    sqlCmd.Parameters.AddWithValue("p_item_name", itemName);
                    adapter.Fill(dataSet);

                    foreach (DataRow row in dataSet.Tables[0].Rows)
                    {
                        if (model.ItemName == null)
                            model.ItemName = (string)row["item_name"];

                        model.History.Add(new ItemHistoryModel.ItemHistoryRecordModel()
                        {
                            AuctionDate = ((DateTime)row["auction_date"]).ToShortDateString(),
                            Price = (int)row["price"],
                            SellerName = (string)row["seller_name"],
                            IsForSaleNow = Convert.ToBoolean(row["is_for_sale_now"])
                        });
                    }
                }

                // Build model's median price properties
                using (var sqlCmd = new MySqlCommand("item_prices_select_by_item", sqlConn))
                using (var adapter = new MySqlDataAdapter(sqlCmd))
                using (var dataSet = new DataSet())
                {
                    sqlCmd.CommandType = CommandType.StoredProcedure;
                    sqlCmd.Parameters.AddWithValue("p_item_name", itemName);
                    adapter.Fill(dataSet);

                    if (dataSet.Tables[0].Rows.Count > 0)
                    {
                        model.SevenDayLowestPrice = convertDbNull(dataSet.Tables[0].Rows[0], "seven_day_lowest");
                        model.SevenDayMedianPrice = convertDbNull(dataSet.Tables[0].Rows[0], "seven_day_median");
                        model.ThirtyDayLowestPrice = convertDbNull(dataSet.Tables[0].Rows[0], "thirty_day_lowest");
                        model.ThirtyDayMedianPrice = convertDbNull(dataSet.Tables[0].Rows[0], "thirty_day_median");
                        model.NinetyDayLowestPrice = convertDbNull(dataSet.Tables[0].Rows[0], "ninety_day_lowest");
                        model.NinetyDayMedianPrice = convertDbNull(dataSet.Tables[0].Rows[0], "ninety_day_median");
                        model.OneYearLowestPrice = convertDbNull(dataSet.Tables[0].Rows[0], "one_year_lowest");
                        model.OneYearMedianPrice = convertDbNull(dataSet.Tables[0].Rows[0], "one_year_median");
                        model.LifetimeLowestPrice = convertDbNull(dataSet.Tables[0].Rows[0], "lifetime_lowest");
                        model.LifetimeMedianPrice = convertDbNull(dataSet.Tables[0].Rows[0], "lifetime_median");
                    }
                }

                // build the model's item stats
                model.ItemStats = getItemStatsModel(sqlConn, itemName);
            }

            return Json(model);
        }

        public IActionResult HotDealz(string timeframe, int? minPrice, int? maxPrice, int? maxAmountAboveLowest, int? maxPercentAboveLowest, int? minPercentBelowMedian, int? minAmountBelowMedian)
        {
            var model = new HotDealzModel();

            using (var sqlConn = new MySqlConnection(config["ConnectionString"]))
            using (var sqlCmd = new MySqlCommand("hot_dealz_select", sqlConn))
            using (var adapter = new MySqlDataAdapter(sqlCmd))
            using (var dataSet = new DataSet())
            {
                sqlConn.Open();

                sqlCmd.CommandType = CommandType.StoredProcedure;
                sqlCmd.Parameters.AddWithValue("p_timeframe", timeframe);
                sqlCmd.Parameters.AddWithValue("p_min_price", minPrice);
                sqlCmd.Parameters.AddWithValue("p_max_price", maxPrice);
                sqlCmd.Parameters.AddWithValue("p_max_percent_above_lowest", maxPercentAboveLowest);
                sqlCmd.Parameters.AddWithValue("p_max_amount_above_lowest", maxAmountAboveLowest);
                sqlCmd.Parameters.AddWithValue("p_min_percent_below_median", minPercentBelowMedian);
                sqlCmd.Parameters.AddWithValue("p_min_amount_below_median", minAmountBelowMedian);
                adapter.Fill(dataSet);

                foreach (DataRow row in dataSet.Tables[0].Rows)
                {
                    string itemName = (string)row["item_name"];

                    model.Dealz.Add(new HotDealzModel.HotDealzRecordModel()
                    {
                        ItemName = itemName,
                        Price = (int)row["price"],
                        SellerName = (string)row["seller_name"],
                        LowestPrice = Convert.ToInt32(row["lowest_price"]),
                        PercentAboveLowest = Convert.ToInt32(row["percent_above_lowest"]),
                        AmountAboveLowest = Convert.ToInt32(row["amount_above_lowest"]),
                        MedianPrice = Convert.ToInt32(row["median_price"]),
                        PercentBelowMedian = Convert.ToInt32(row["percent_below_median"]),
                        AmountBelowMedian = Convert.ToInt32(row["amount_below_median"])
                    });

                    // Run a separate query to fetch the stats rows for each unique item name in the results
                    if (!model.ItemStats.Any(itemModel => itemModel.ItemName == itemName))
                    {
                        var itemStatsModel = getItemStatsModel(sqlConn, itemName);
                        if (itemStatsModel != null)
                            model.ItemStats.Add(itemStatsModel);
                    }
                }
            }

            return Json(model);
        }

        private ItemStatsModel getItemStatsModel(MySqlConnection sqlConn, string itemName)
        {
            using (var statsCmd = new MySqlCommand("item_stats_select_by_item", sqlConn))
            using (var statsDA = new MySqlDataAdapter(statsCmd))
            using (var statsDS = new DataSet())
            {
                statsCmd.CommandType = CommandType.StoredProcedure;
                statsCmd.Parameters.AddWithValue("p_item_name", itemName);
                statsDA.Fill(statsDS);

                if (statsDS.Tables[0].Rows.Count == 0)
                    return null;
                else
                {
                    var itemStatsModel = new ItemStatsModel()
                    {
                        ItemName = itemName
                    };

                    foreach (DataRow statsRow in statsDS.Tables[0].Rows)
                    {
                        var statsLineModel = new ItemStatsModel.ItemStatsRecordModel();

                        string parsedStatName = (string)statsRow["parsed_stat_name"];
                        if (String.IsNullOrWhiteSpace(parsedStatName))
                        {
                            statsLineModel.RawLine = (string)statsRow["raw_line"];
                        }
                        else
                        {
                            statsLineModel.ParsedStatName = parsedStatName;
                            statsLineModel.ParsedStatValue = (string)statsRow["parsed_stat_value"];
                        }

                        itemStatsModel.Stats.Add(statsLineModel);
                    }

                    return itemStatsModel;
                }
            }
        }

        private int? convertDbNull(DataRow row, string columnName)
        {
            if (row.IsNull(columnName))
                return null;
            else
                return (int)row[columnName];
        }


        // Error handler (asp.net boilerplate code)
        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
