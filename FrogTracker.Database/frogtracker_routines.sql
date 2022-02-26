-- MySQL dump 10.13  Distrib 8.0.13, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: frogtracker
-- ------------------------------------------------------
-- Server version	8.0.13

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
 SET NAMES utf8 ;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping routines for database 'frogtracker'
--
/*!50003 DROP PROCEDURE IF EXISTS `auction_insert` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `auction_insert`(
	p_item_name VARCHAR(500),
	p_auction_date DATE,
    p_price INT,
    p_seller_name VARCHAR(45),
    p_scrape_id BIGINT(20)
)
BEGIN

	INSERT INTO auction (
		item_name,
        auction_date,
        price,
        seller_name,
        scrape_id,
        last_seen_by_scrape_id
    )
	SELECT
		p_item_name,
        p_auction_date,
        p_price,
        p_seller_name,
        p_scrape_id,
        p_scrape_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `auction_select_by_item_date_price_seller` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `auction_select_by_item_date_price_seller`(
	p_item_name VARCHAR(500),
	p_auction_date DATE,
    p_price INT,
    p_seller_name VARCHAR(45)
)
BEGIN

	SELECT *
	FROM auction 
	WHERE 
		item_name = p_item_name
		AND auction_date = p_auction_date
		AND price = p_price
		AND seller_name = p_seller_name;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `auction_select_by_item_name` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `auction_select_by_item_name`(
	p_item_name VARCHAR(500)
)
BEGIN

	SET @last_finished_scrape_id = (SELECT MAX(scrape_id) FROM scrape WHERE finish_time is not null);
    
	SELECT 
		auction.*,
        CASE
			WHEN auction.last_seen_by_scrape_id >= @last_finished_scrape_id THEN 1
            ELSE 0
            END AS is_for_sale_now
	FROM
		auction
	WHERE
		item_name = p_item_name
	ORDER BY
		auction_date desc,
        price asc,
        seller_name asc;
        
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `auction_select_item_names` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `auction_select_item_names`(
	p_search_string VARCHAR(500)
)
BEGIN

	SELECT DISTINCT
		item_name
	FROM
		auction
	WHERE
		item_name LIKE CONCAT('%', p_search_string, '%')
	ORDER BY
		item_name asc;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `auction_select_item_names_without_prices` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `auction_select_item_names_without_prices`()
BEGIN

	SELECT DISTINCT
		auction.item_name
	FROM
		auction
        LEFT JOIN item_prices ON auction.item_name = item_prices.item_name
	WHERE
		item_prices.item_name is null
	ORDER BY
		auction.item_name asc;
        

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `auction_update` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `auction_update`(
	p_auction_id BIGINT(20),
	p_last_seen_by_scrape_id BIGINT(20)
)
BEGIN

	UPDATE auction
    SET last_seen_by_scrape_id = p_last_seen_by_scrape_id
    WHERE auction_id = p_auction_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `hot_dealz_select` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `hot_dealz_select`(
    p_timeframe VARCHAR(25),
    p_min_price INT(11),
    p_max_price INT(11),
    p_max_percent_above_lowest INT(11),
    p_max_amount_above_lowest INT(11),
	p_min_percent_below_median INT(11),
    p_min_amount_below_median INT(11)
)
BEGIN

	SET @last_finished_scrape_id = (SELECT MAX(scrape_id) FROM scrape WHERE finish_time is not null);

	SELECT
		auction.item_name,
        auction.price,
        auction.seller_name,
        
        -- lowest fields
        CASE 
			WHEN p_timeframe = '7day' THEN item_prices.seven_day_lowest
			WHEN p_timeframe = '30day' THEN item_prices.thirty_day_lowest 
			WHEN p_timeframe = '90day' THEN item_prices.ninety_day_lowest 
			WHEN p_timeframe = '1year' THEN item_prices.one_year_lowest
			ELSE item_prices.lifetime_lowest
			END as lowest_price,
		
		ROUND(((auction.price - CASE 
							WHEN p_timeframe = '7day' THEN item_prices.seven_day_lowest
							WHEN p_timeframe = '30day' THEN item_prices.thirty_day_lowest 
							WHEN p_timeframe = '90day' THEN item_prices.ninety_day_lowest 
							WHEN p_timeframe = '1year' THEN item_prices.one_year_lowest
							ELSE item_prices.lifetime_lowest
							END) / CASE 
										WHEN p_timeframe = '7day' THEN item_prices.seven_day_lowest
										WHEN p_timeframe = '30day' THEN item_prices.thirty_day_lowest 
										WHEN p_timeframe = '90day' THEN item_prices.ninety_day_lowest 
										WHEN p_timeframe = '1year' THEN item_prices.one_year_lowest
										ELSE item_prices.lifetime_lowest
										END) * 100) as percent_above_lowest,
                            
		(auction.price - CASE 
							WHEN p_timeframe = '7day' THEN item_prices.seven_day_lowest
							WHEN p_timeframe = '30day' THEN item_prices.thirty_day_lowest 
							WHEN p_timeframe = '90day' THEN item_prices.ninety_day_lowest 
							WHEN p_timeframe = '1year' THEN item_prices.one_year_lowest
							ELSE item_prices.lifetime_lowest
							END) as amount_above_lowest,
            
            
        -- median fields
        CASE 
			WHEN p_timeframe = '7day' THEN item_prices.seven_day_median 
			WHEN p_timeframe = '30day' THEN item_prices.thirty_day_median 
			WHEN p_timeframe = '90day' THEN item_prices.ninety_day_median 
			WHEN p_timeframe = '1year' THEN item_prices.one_year_median 
			ELSE item_prices.lifetime_median
			END as median_price,
		
		ROUND(((CASE 
			WHEN p_timeframe = '7day' THEN item_prices.seven_day_median 
			WHEN p_timeframe = '30day' THEN item_prices.thirty_day_median 
			WHEN p_timeframe = '90day' THEN item_prices.ninety_day_median 
			WHEN p_timeframe = '1year' THEN item_prices.one_year_median 
			ELSE item_prices.lifetime_median
			END - auction.price) / CASE 
										WHEN p_timeframe = '7day' THEN item_prices.seven_day_median 
										WHEN p_timeframe = '30day' THEN item_prices.thirty_day_median 
										WHEN p_timeframe = '90day' THEN item_prices.ninety_day_median 
										WHEN p_timeframe = '1year' THEN item_prices.one_year_median 
										ELSE item_prices.lifetime_median
										END) * 100) as percent_below_median,
            
		(CASE 
			WHEN p_timeframe = '7day' THEN item_prices.seven_day_median 
			WHEN p_timeframe = '30day' THEN item_prices.thirty_day_median 
			WHEN p_timeframe = '90day' THEN item_prices.ninety_day_median 
			WHEN p_timeframe = '1year' THEN item_prices.one_year_median 
			ELSE item_prices.lifetime_median
			END - auction.price) as amount_below_median

	FROM
		auction
        INNER JOIN item_prices ON item_prices.item_name = auction.item_name
	WHERE
		-- only auctions seen by the most recent finished scrape, or by an in-progress unfinished scrape
		auction.last_seen_by_scrape_id >= @last_finished_scrape_id
        
        -- ignore auctions with only 1 price in their history for the selected period
        AND (
			(p_timeframe = '7day' AND item_prices.seven_day_lowest <> item_prices.seven_day_median)
            OR (p_timeframe = '30day' AND item_prices.thirty_day_lowest <> item_prices.thirty_day_median)
            OR (p_timeframe = '90day' AND item_prices.ninety_day_lowest <> item_prices.ninety_day_median)
            OR (p_timeframe = '1year' AND item_prices.one_year_lowest <> item_prices.one_year_median)
            OR (item_prices.lifetime_lowest <> item_prices.lifetime_median)
        )
        
        -- apply filter p_min_price
        AND (p_min_price is null OR auction.price >= p_min_price)
        
        -- apply filter p_max_price
		AND (p_max_price is null OR auction.price <= p_max_price)
        
        -- apply filter parameter p_max_percent_above_lowest
        AND (p_max_percent_above_lowest is null OR auction.price <= CEILING((1.00 + (p_max_percent_above_lowest * 0.01)) * CASE 
																					WHEN p_timeframe = '7day' THEN item_prices.seven_day_lowest
																					WHEN p_timeframe = '30day' THEN item_prices.thirty_day_lowest 
																					WHEN p_timeframe = '90day' THEN item_prices.ninety_day_lowest 
																					WHEN p_timeframe = '1year' THEN item_prices.one_year_lowest
																					ELSE item_prices.lifetime_lowest
																					END))
                                                                                    
        -- apply filter parameter p_max_amount_above_lowest
         AND (p_max_amount_above_lowest is null OR p_max_amount_above_lowest >= (auction.price - CASE 
							WHEN p_timeframe = '7day' THEN item_prices.seven_day_lowest
							WHEN p_timeframe = '30day' THEN item_prices.thirty_day_lowest 
							WHEN p_timeframe = '90day' THEN item_prices.ninety_day_lowest 
							WHEN p_timeframe = '1year' THEN item_prices.one_year_lowest
							ELSE item_prices.lifetime_lowest
							END))
                            
        -- apply filter parameter p_min_percent_below_median
        AND (p_min_percent_below_median is null OR auction.price <= CEILING((1.00 - (p_min_percent_below_median * 0.01)) * CASE 
																					WHEN p_timeframe = '7day' THEN item_prices.seven_day_median 
																					WHEN p_timeframe = '30day' THEN item_prices.thirty_day_median 
																					WHEN p_timeframe = '90day' THEN item_prices.ninety_day_median 
																					WHEN p_timeframe = '1year' THEN item_prices.one_year_median 
																					ELSE item_prices.lifetime_median
																					END))
		
        -- apply filter parameter p_min_amount_below_median
        AND (p_min_amount_below_median is null OR p_min_amount_below_median <= (CASE 
											WHEN p_timeframe = '7day' THEN item_prices.seven_day_median 
											WHEN p_timeframe = '30day' THEN item_prices.thirty_day_median 
											WHEN p_timeframe = '90day' THEN item_prices.ninety_day_median 
											WHEN p_timeframe = '1year' THEN item_prices.one_year_median 
											ELSE item_prices.lifetime_median
											END - auction.price))
	ORDER BY
		amount_above_lowest asc;
        
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `item_prices_insert` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `item_prices_insert`(
	p_item_name VARCHAR(500),
    p_seven_day_lowest INT(11),
    p_seven_day_median INT(11),
    p_seven_day_highest INT(11),
    p_thirty_day_lowest INT(11),
	p_thirty_day_median INT(11),
    p_thirty_day_highest INT(11),
    p_ninety_day_lowest INT(11),
	p_ninety_day_median INT(11),
    p_ninety_day_highest INT(11),
    p_one_year_lowest INT(11),
    p_one_year_median INT(11),
    p_one_year_highest INT(11),
    p_lifetime_lowest INT(11),
    p_lifetime_median INT(11),
    p_lifetime_highest INT(11),
    p_last_updated DATETIME
)
BEGIN
	INSERT INTO item_prices (
		item_name,
        seven_day_lowest,
		seven_day_median,
        seven_day_highest,
        thirty_day_lowest,
		thirty_day_median,
        thirty_day_highest,
        ninety_day_lowest,
		ninety_day_median,
        ninety_day_highest,
        one_year_lowest,
		one_year_median,
        one_year_highest,
        lifetime_lowest,
		lifetime_median,
        lifetime_highest,
		last_updated)
    SELECT
		p_item_name,
        p_seven_day_lowest,
		p_seven_day_median,
        p_seven_day_highest,
        p_thirty_day_lowest,
		p_thirty_day_median,
        p_thirty_day_highest,
        p_ninety_day_lowest,
		p_ninety_day_median,
        p_ninety_day_highest,
        p_one_year_lowest,
		p_one_year_median,
        p_one_year_highest,
        p_lifetime_lowest,
		p_lifetime_median,
        p_lifetime_highest,
		p_last_updated;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `item_prices_select_by_item` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `item_prices_select_by_item`(
	p_item_name VARCHAR(500)
)
BEGIN

	SELECT *
    FROM item_prices
    WHERE item_name = p_item_name;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `item_prices_select_by_last_updated` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `item_prices_select_by_last_updated`(
	p_max_last_updated DATETIME
)
BEGIN

	SELECT *
    FROM item_prices
    WHERE last_updated <= p_max_last_updated
    ORDER BY last_updated asc;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `item_prices_update` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `item_prices_update`(
	p_item_name VARCHAR(500),
    p_seven_day_lowest INT(11),
    p_seven_day_median INT(11),
    p_seven_day_highest INT(11),
    p_thirty_day_lowest INT(11),
	p_thirty_day_median INT(11),
    p_thirty_day_highest INT(11),
    p_ninety_day_lowest INT(11),
	p_ninety_day_median INT(11),
    p_ninety_day_highest INT(11),
    p_one_year_lowest INT(11),
    p_one_year_median INT(11),
    p_one_year_highest INT(11),
    p_lifetime_lowest INT(11),
    p_lifetime_median INT(11),
    p_lifetime_highest INT(11),
    p_last_updated DATETIME
)
BEGIN

	UPDATE item_prices
    SET
		seven_day_lowest = p_seven_day_lowest,
		seven_day_median = p_seven_day_median,
		seven_day_highest = p_seven_day_highest,
		thirty_day_lowest = p_thirty_day_lowest,
		thirty_day_median = p_thirty_day_median,
		thirty_day_highest = p_thirty_day_highest,
		ninety_day_lowest = p_ninety_day_lowest,
		ninety_day_median = p_ninety_day_median,
		ninety_day_highest = p_ninety_day_highest,
		one_year_lowest = p_one_year_lowest,
		one_year_median = p_one_year_median,
		one_year_highest = p_one_year_highest,
		lifetime_lowest = p_lifetime_lowest,
		lifetime_median = p_lifetime_median,
		lifetime_highest = p_lifetime_highest,
		last_updated = p_last_updated
    WHERE
		item_name = p_item_name;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `item_stats_delete` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `item_stats_delete`(
	p_item_name VARCHAR(500)
)
BEGIN

	DELETE
    FROM item_stats
    WHERE item_name = p_item_name;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `item_stats_insert` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `item_stats_insert`(
	p_item_name VARCHAR(500),
    p_line_number INT(11),
    p_raw_line VARCHAR(500),
    p_parsed_stat_name VARCHAR(500),
    p_parsed_stat_value VARCHAR(500),
    p_parsed_stat_value_double DOUBLE,
    p_scrape_id BIGINT(20)
)
BEGIN

	INSERT INTO item_stats (
		item_name,
        line_number,
        raw_line,
        parsed_stat_name,
        parsed_stat_value,
        parsed_stat_value_double,
		scrape_id)
	SELECT
		p_item_name,
        p_line_number,
        p_raw_line,
        p_parsed_stat_name,
        p_parsed_stat_value,
        p_parsed_stat_value_double,
		p_scrape_id;
        
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `item_stats_select_by_item` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `item_stats_select_by_item`(
	p_item_name VARCHAR(500)
)
BEGIN
	
    SELECT *
	FROM item_stats
    WHERE item_name = p_item_name
    ORDER BY line_number asc;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `scrape_insert` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `scrape_insert`(
	p_scrape_time DATETIME
)
BEGIN
	
    INSERT INTO scrape (scrape_time)
    SELECT p_scrape_time;
    
    SELECT LAST_INSERT_ID() AS `scrape_id`;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `scrape_select_most_recent` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `scrape_select_most_recent`()
BEGIN

	SELECT
		scrape_id,
		scrape_time
	FROM
		scrape
	WHERE
		finish_time is not null
	ORDER BY
		scrape_id desc
	LIMIT 1;
        
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `scrape_update` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `scrape_update`(
	p_scrape_id BIGINT(20),
	p_finish_time DATETIME,
    p_error_count INT(11),
    p_new_auction_count INT(11),
    p_existing_auction_count INT(11)
)
BEGIN

	UPDATE scrape
    SET
		finish_time = p_finish_time,
        error_count = p_error_count,
        new_auction_count = p_new_auction_count,
        existing_auction_count = p_existing_auction_count
	WHERE
		scrape_id = p_scrape_id;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2022-02-26 10:50:48
