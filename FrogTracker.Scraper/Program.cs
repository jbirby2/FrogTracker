using FrogTracker.Scraper.Models;
using HtmlAgilityPack;
using Microsoft.Extensions.Configuration;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Net;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web;

namespace FrogTracker.Scraper
{
    class Program
    {
        static void Main(string[] args)
        {
            var builder = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json");

            var config = builder.Build();

            using (var webClient = new WebClient())
            using (var sqlConn = new MySqlConnection(config["ConnectionString"]))
            {
                // Create a new scrapeID
                var scrapeInsertParams = new Dictionary<string, object>();
                scrapeInsertParams.Add("p_scrape_time", DateTime.UtcNow);
                var scrapeInsertDataset = executeQuery(sqlConn, "scrape_insert", scrapeInsertParams);
                long scrapeID = Convert.ToInt64(scrapeInsertDataset.Tables[0].Rows[0]["scrape_id"]);

                var timeToWaitBetweenServerHits = TimeSpan.FromMilliseconds(Int32.Parse(config["MillisecondsToWaitBetweenServerHits"]));
                var auctionDate = DateTime.UtcNow.Date;

                Console.WriteLine("Starting scrape (scape_id " + scrapeID.ToString() + ", auction_date " + auctionDate.ToShortDateString() + ", pausing " + config["MillisecondsToWaitBetweenServerHits"] + "ms between server hits)");

                try
                {
                    int startIndex = 0;

                    int newAuctionCount = 0;
                    int errorCount = 0;
                    int existingAuctionCount = 0;

                    sqlConn.Open();

                    bool keepGoing = true;
                    while (keepGoing)
                    {
                        string responseHtml = webClient.DownloadString(String.Format("https://www.lazaruseq.com/Magelo/index.php?page=bazaar&class=-1&race=-1&stat=-1&slot=-1&aug_type=-1&type=-1&pricemin=&pricemax=&item=&start={0}&trader=&direction=ASC&orderby=name", startIndex));

                        var resultsPageDoc = new HtmlDocument();
                        resultsPageDoc.LoadHtml(responseHtml);

                        var itemLinks = resultsPageDoc.DocumentNode.Descendants("a").Where(d => d.Attributes["class"]?.Value == "CB_HoverParent");

                        if (itemLinks.Any())
                        {
                            foreach (var itemLink in itemLinks)
                            {
                                try
                                {
                                    // Parse auction data out of the HTML
                                    string itemName = itemLink.InnerText.Trim();
                                    int price = Convert.ToInt32(itemLink.ParentNode.NextSibling.NextSibling.InnerText.Trim().Replace(",", "").Split(' ')[0]);
                                    string sellerName = itemLink.ParentNode.NextSibling.NextSibling.NextSibling.NextSibling.Descendants("a").First().InnerText.Trim();

                                    // Get auctionDataset
                                    var auctionSelectParams = new Dictionary<string, object>();
                                    auctionSelectParams.Add("p_item_name", itemName);
                                    auctionSelectParams.Add("p_auction_date", auctionDate);
                                    auctionSelectParams.Add("p_price", price);
                                    auctionSelectParams.Add("p_seller_name", sellerName);
                                    var auctionDataset = executeQuery(sqlConn, "auction_select_by_item_date_price_seller", auctionSelectParams);

                                    // Insert or update auction row
                                    if (auctionDataset.Tables[0].Rows.Count == 0)
                                    {
                                        Console.WriteLine("INSERTING AUCTION: " + itemName + " : " + price.ToString() + " : " + sellerName);

                                        using (var insertAuctionCmd = new MySqlCommand("auction_insert", sqlConn))
                                        {
                                            insertAuctionCmd.CommandType = CommandType.StoredProcedure;
                                            insertAuctionCmd.Parameters.AddWithValue("p_item_name", itemName);
                                            insertAuctionCmd.Parameters.AddWithValue("p_auction_date", auctionDate);
                                            insertAuctionCmd.Parameters.AddWithValue("p_price", price);
                                            insertAuctionCmd.Parameters.AddWithValue("p_seller_name", sellerName);
                                            insertAuctionCmd.Parameters.AddWithValue("p_scrape_id", scrapeID);
                                            insertAuctionCmd.ExecuteNonQuery();
                                        }

                                        newAuctionCount++;

                                        updatePrices(sqlConn, itemName);
                                    }
                                    else
                                    {
                                        Console.WriteLine("UPDATING AUCTION: " + itemName + " : " + price.ToString() + " : " + sellerName);

                                        using (var updateAuctionCmd = new MySqlCommand("auction_update", sqlConn))
                                        {
                                            updateAuctionCmd.CommandType = CommandType.StoredProcedure;
                                            updateAuctionCmd.Parameters.AddWithValue("p_auction_id", (long)auctionDataset.Tables[0].Rows[0]["auction_id"]);
                                            updateAuctionCmd.Parameters.AddWithValue("p_last_seen_by_scrape_id", scrapeID);
                                            updateAuctionCmd.ExecuteNonQuery();
                                        }

                                        existingAuctionCount++;
                                    }


                                    Console.WriteLine("REBUILDING STATS: " + itemName);

                                    // Parse item data out of HTML
                                    var itemPopUpDiv = resultsPageDoc.DocumentNode.Descendants("div").Where(d => d.Id == itemLink.Attributes["hoverChild"].Value.Substring(1)).First();
                                    var itemDetailsUrl = itemPopUpDiv.ChildNodes[1].ChildNodes[1].Attributes["href"].Value;
                                    string itemID = itemDetailsUrl.Substring(itemDetailsUrl.LastIndexOf('=') + 1);

                                    var imageNode = itemPopUpDiv.ChildNodes[3].ChildNodes[1];

                                    // TODO: pull and store images if they don't exist
                                    string imageUrl = "https://www.lazaruseq.com/Magelo/" + itemPopUpDiv.ChildNodes[3].ChildNodes[1].Attributes["src"].Value;


                                    // Delete and rebuild the item_stats rows
                                    var transaction = sqlConn.BeginTransaction();
                                    try
                                    {
                                        // Delete existing stats for this item
                                        var itemStatsDeleteParams = new Dictionary<string, object>();
                                        itemStatsDeleteParams.Add("p_item_name", itemName);
                                        executeQuery(sqlConn, "item_stats_delete", itemStatsDeleteParams);

                                        // Insert our own line for the item's "ID" stat
                                        var itemStatsInsertParams = new Dictionary<string, object>();
                                        itemStatsInsertParams.Add("p_scrape_id", scrapeID);
                                        itemStatsInsertParams.Add("p_item_name", itemName);
                                        itemStatsInsertParams.Add("p_line_number", 1);
                                        itemStatsInsertParams.Add("p_raw_line", "ID: " + itemID);
                                        itemStatsInsertParams.Add("p_parsed_stat_name", "ID");
                                        itemStatsInsertParams.Add("p_parsed_stat_value", itemID);
                                        try
                                        {
                                            itemStatsInsertParams.Add("p_parsed_stat_value_double", Double.Parse(itemID));
                                        }
                                        catch
                                        {
                                            itemStatsInsertParams.Add("p_parsed_stat_value_double", null);
                                        }
                                        executeQuery(sqlConn, "item_stats_insert", itemStatsInsertParams);

                                        // Insert lines for the rest of the item's stats
                                        var nextStatLineNode = imageNode.NextSibling;
                                        bool tagsLineAdded = false;
                                        string rawLine = "";
                                        int lineNumber = 2;
                                        while (nextStatLineNode != null)
                                        {
                                            if (nextStatLineNode.Name == "br")
                                            {
                                                // We've reached the end of a stats line, so write it to the database

                                                rawLine = HttpUtility.HtmlDecode(rawLine.Trim());
                                                rawLine = Regex.Replace(rawLine, @"\s+", " "); // condense any places in the string where there are multiple spaces in a row

                                                Console.WriteLine("     " + rawLine);

                                                itemStatsInsertParams.Clear();
                                                itemStatsInsertParams.Add("p_scrape_id", scrapeID);
                                                itemStatsInsertParams.Add("p_item_name", itemName);
                                                itemStatsInsertParams.Add("p_line_number", lineNumber);
                                                itemStatsInsertParams.Add("p_raw_line", rawLine);
                                                if (rawLine.Contains(':'))
                                                {
                                                    int firstColonIndex = rawLine.IndexOf(':');
                                                    string parsedStatName = rawLine.Substring(0, firstColonIndex).Trim();
                                                    string parsedStatValue = rawLine.Substring(firstColonIndex + 1).Trim();

                                                    itemStatsInsertParams.Add("p_parsed_stat_name", parsedStatName);
                                                    itemStatsInsertParams.Add("p_parsed_stat_value", parsedStatValue);
                                                    try
                                                    {
                                                        itemStatsInsertParams.Add("p_parsed_stat_value_double", Double.Parse(parsedStatValue));
                                                    }
                                                    catch
                                                    {
                                                        itemStatsInsertParams.Add("p_parsed_stat_value_double", null);
                                                    }
                                                }
                                                else
                                                {
                                                    if (tagsLineAdded)
                                                    {
                                                        itemStatsInsertParams.Add("p_parsed_stat_name", "Description");
                                                    }
                                                    else
                                                    {
                                                        itemStatsInsertParams.Add("p_parsed_stat_name", "Tags");
                                                        tagsLineAdded = true;
                                                    }
                                                    itemStatsInsertParams.Add("p_parsed_stat_value", rawLine);
                                                    itemStatsInsertParams.Add("p_parsed_stat_value_double", null);
                                                }

                                                executeQuery(sqlConn, "item_stats_insert", itemStatsInsertParams);

                                                // Reset variables for the next stats line
                                                rawLine = "";
                                                lineNumber++;
                                            }
                                            else
                                            {
                                                if (!String.IsNullOrWhiteSpace(nextStatLineNode.InnerText))
                                                {
                                                    if (rawLine.Length > 0)
                                                        rawLine += " ";
                                                    rawLine += nextStatLineNode.InnerText;
                                                }
                                            }
                                            
                                            nextStatLineNode = nextStatLineNode.NextSibling;
                                        }

                                        transaction.Commit();
                                    }
                                    catch (Exception ex)
                                    {
                                        transaction.Rollback();
                                        throw;
                                    }
                                }
                                catch (Exception ex)
                                {
                                    errorCount++;
                                    Console.WriteLine("*** ERROR: " + ex.GetType() + Environment.NewLine + ex.Message + Environment.NewLine + ex.StackTrace);
                                }
                            }

                            if (System.Diagnostics.Debugger.IsAttached)
                            {
                                Console.WriteLine("** DEBUGGER DETECTED: stopping after 1 page of results");
                                keepGoing = false;
                            }
                            else
                            {
                                startIndex += 25;
                                Thread.Sleep(timeToWaitBetweenServerHits);
                            }
                        }
                        else
                        {
                            keepGoing = false;
                        }
                    }// end while(keepGoing)
                    


                    Console.WriteLine("----------- Checking for items without prices... -----------");

                    var missingPricesParams = new Dictionary<string, object>();
                    var missingPricesDataset = executeQuery(sqlConn, "auction_select_item_names_without_prices", missingPricesParams);
                    foreach (DataRow row in missingPricesDataset.Tables[0].Rows)
                    {
                        try
                        {
                            updatePrices(sqlConn, (string)row["item_name"]);
                        }
                        catch (Exception ex)
                        {
                            errorCount++;
                            Console.WriteLine("*** ERROR: " + ex.GetType() + Environment.NewLine + ex.Message + Environment.NewLine + ex.StackTrace);
                        }
                    }

                    Console.WriteLine("----------- Checking for items with outdated prices... -----------");

                    var outdatedPricesParams = new Dictionary<string, object>();
                    outdatedPricesParams.Add("p_max_last_updated", DateTime.UtcNow.AddDays(-1));
                    var outdatedPricesDataset = executeQuery(sqlConn, "item_prices_select_by_last_updated", outdatedPricesParams);
                    foreach (DataRow row in outdatedPricesDataset.Tables[0].Rows)
                    {
                        try
                        {
                            updatePrices(sqlConn, (string)row["item_name"]);
                        }
                        catch (Exception ex)
                        {
                            errorCount++;
                            Console.WriteLine("*** ERROR: " + ex.GetType() + Environment.NewLine + ex.Message + Environment.NewLine + ex.StackTrace);
                        }
                    }

                    // finalize the scrape
                    using (var sqlCmd = new MySqlCommand("scrape_update", sqlConn))
                    {
                        sqlCmd.CommandType = CommandType.StoredProcedure;
                        sqlCmd.Parameters.AddWithValue("p_scrape_id", scrapeID);
                        sqlCmd.Parameters.AddWithValue("p_finish_time", DateTime.UtcNow);
                        sqlCmd.Parameters.AddWithValue("p_error_count", errorCount);
                        sqlCmd.Parameters.AddWithValue("p_new_auction_count", newAuctionCount);
                        sqlCmd.Parameters.AddWithValue("p_existing_auction_count", existingAuctionCount);
                        sqlCmd.ExecuteNonQuery();
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("*** ERROR: " + ex.GetType() + Environment.NewLine + ex.Message + Environment.NewLine + ex.StackTrace);
                }
                finally
                {
                    try
                    {
                        sqlConn.Close();
                    }
                    catch { }

                    if (System.Diagnostics.Debugger.IsAttached)
                    {
                        Console.WriteLine("** DEBUGGER DETECTED: press any key to exit. **");
                        Console.ReadKey();
                    }
                }


            } // end usings

        }

        private static DataSet executeQuery(MySqlConnection sqlConn, string procName, Dictionary<string,object> procParams)
        {
            using (var cmd = new MySqlCommand(procName, sqlConn))
            using (var da = new MySqlDataAdapter(cmd))
            using (var ds = new DataSet())
            {
                cmd.CommandType = CommandType.StoredProcedure;
                foreach (string key in procParams.Keys)
                {
                    cmd.Parameters.AddWithValue(key, procParams[key]);
                }

                da.Fill(ds);

                return ds;
            }
        }

        private static void updatePrices(MySqlConnection sqlConn, string itemName)
        {
            var auctionsParams = new Dictionary<string, object>();
            auctionsParams.Add("p_item_name", itemName);
            var auctionsDataset = executeQuery(sqlConn, "auction_select_by_item_name", auctionsParams);

            // Build auctions
            var auctions = new List<Auction>();
            foreach (DataRow row in auctionsDataset.Tables[0].Rows)
            {
                auctions.Add(new Auction()
                {
                    ItemName = (string)row["item_name"],
                    AuctionDate = (DateTime)row["auction_date"],
                    Price = (int)row["price"],
                    SellerName = (string)row["seller_name"]
                });
            }

            var pricesProcParams = new Dictionary<string, object>();
            pricesProcParams.Add("p_item_name", itemName);

            // 7 day prices
            var sevenDayAuctions = auctions.Where(auction => auction.AuctionDate >= DateTime.UtcNow.AddDays(-7));
            if (sevenDayAuctions.Any())
            {
                pricesProcParams.Add("p_seven_day_lowest", sevenDayAuctions.Min(auction => auction.Price));
                pricesProcParams.Add("p_seven_day_median", sevenDayAuctions.Median(auction => auction.Price).Value);
                pricesProcParams.Add("p_seven_day_highest", sevenDayAuctions.Max(auction => auction.Price));
            }
            else
            {
                pricesProcParams.Add("p_seven_day_lowest", null);
                pricesProcParams.Add("p_seven_day_median", null);
                pricesProcParams.Add("p_seven_day_highest", null);
            }

            // 30 day prices
            var thirtyDayAuctions = auctions.Where(auction => auction.AuctionDate >= DateTime.UtcNow.AddDays(-30));
            if (thirtyDayAuctions.Any())
            {
                pricesProcParams.Add("p_thirty_day_lowest", thirtyDayAuctions.Min(auction => auction.Price));
                pricesProcParams.Add("p_thirty_day_median", thirtyDayAuctions.Median(auction => auction.Price).Value);
                pricesProcParams.Add("p_thirty_day_highest", thirtyDayAuctions.Max(auction => auction.Price));
            }
            else
            {
                pricesProcParams.Add("p_thirty_day_lowest", null);
                pricesProcParams.Add("p_thirty_day_median", null);
                pricesProcParams.Add("p_thirty_day_highest", null);
            }

            // 90 day prices
            var ninetyDayAuctions = auctions.Where(auction => auction.AuctionDate >= DateTime.UtcNow.AddDays(-90));
            if (ninetyDayAuctions.Any())
            {
                pricesProcParams.Add("p_ninety_day_lowest", ninetyDayAuctions.Min(auction => auction.Price));
                pricesProcParams.Add("p_ninety_day_median", ninetyDayAuctions.Median(auction => auction.Price).Value);
                pricesProcParams.Add("p_ninety_day_highest", ninetyDayAuctions.Max(auction => auction.Price));
            }
            else
            {
                pricesProcParams.Add("p_ninety_day_lowest", null);
                pricesProcParams.Add("p_ninety_day_median", null);
                pricesProcParams.Add("p_ninety_day_highest", null);
            }

            // 1 year prices
            var oneYearAuctions = auctions.Where(auction => auction.AuctionDate >= DateTime.UtcNow.AddYears(-1));
            if (oneYearAuctions.Any())
            {
                pricesProcParams.Add("p_one_year_lowest", oneYearAuctions.Min(auction => auction.Price));
                pricesProcParams.Add("p_one_year_median", oneYearAuctions.Median(auction => auction.Price).Value);
                pricesProcParams.Add("p_one_year_highest", oneYearAuctions.Max(auction => auction.Price));
            }
            else
            {
                pricesProcParams.Add("p_one_year_lowest", null);
                pricesProcParams.Add("p_one_year_median", null);
                pricesProcParams.Add("p_one_year_highest", null);
            }

            // Lifetime prices
            pricesProcParams.Add("p_lifetime_lowest", auctions.Min(auction => auction.Price));
            pricesProcParams.Add("p_lifetime_median", auctions.Median(auction => auction.Price).Value);
            pricesProcParams.Add("p_lifetime_highest", auctions.Max(auction => auction.Price));

            pricesProcParams.Add("p_last_updated", DateTime.UtcNow);

            // Set procName
            string procName;
            var insertOrUpdateParams = new Dictionary<string, object>();
            insertOrUpdateParams.Add("p_item_name", itemName);
            var medianDataset = executeQuery(sqlConn, "item_prices_select_by_item", insertOrUpdateParams);
            if (medianDataset.Tables[0].Rows.Count == 0)
            {
                Console.WriteLine("INSERTING PRICES: " + itemName);
                procName = "item_prices_insert";
            }
            else
            {
                Console.WriteLine("UPDATING PRICES: " + itemName);
                procName = "item_prices_update";
            }

            using (var sqlCmd = new MySqlCommand(procName, sqlConn))
            {
                sqlCmd.CommandType = CommandType.StoredProcedure;
                foreach (string key in pricesProcParams.Keys)
                {
                    sqlCmd.Parameters.AddWithValue(key, pricesProcParams[key]);
                }
                sqlCmd.ExecuteNonQuery();
            }
        }
    }
}
