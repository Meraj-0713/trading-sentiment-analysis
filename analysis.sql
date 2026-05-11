-- ================================================================
-- PROJECT  : Trading Behavior & Sentiment Analysis
-- AUTHOR   : [Your Name]
-- DATE     : May 2026
-- TOOL     : SQL Server 
-- ================================================================
-- OBJECTIVE:
--   Analyse whether market sentiment (Fear, Greed, Neutral,
--   Extreme Greed) influences trader performance and behavior.
--
-- TABLES:
--   historical_data1 →         raw trade-level data
--   fear_greed_indes →         daily Fear & Greed sentiment index

-- SIDE COLUMN RULE:
--   BUY  = trade entry row  (no PnL recorded here)
--   SELL = trade exit row   (PnL is recorded here)
--   → Always filter side = 'sell' for PnL and trade counts
--   → Never add WHERE side filter when counting long/short bias

-- ================================================================
-- Part A : KEY METRICS
-- ================================================================

-- 1A. Daily PnL Per Account
-- Shows how much each account earned/lost each day
-- and which sentiment was active that day

SELECT
h.date     AS trade_date,
h.account,
f.classification,
ROUND(SUM(TRY_CAST(h.closed_pnl AS FLOAT)), 2)  AS daily_pnl,
COUNT(*) AS trades_that_day
FROM historical_data1 h
JOIN fear_greed_index_ f ON h.date = f.date
WHERE h.side = 'sell'
GROUP BY h.date, h.account, f.classification
ORDER BY trade_date;

-- ----------------------------------------------------------------
-- 1B. Win Rate and Average Trade Size Per Account
-- Baseline per-account performance before segmentation
-- ----------------------------------------------------------------

select account ,
count(*)as total_traders,
cast(avg(size_usd)as decimal(10,2)) as avg_trade_size,
cast(round((sum(case when closed_pnl>0 then 1 else 0 end) *100.0/count(*)),2) as decimal(10,2)) as win_rate_percent
from historical_data1 where side='sell'
group by account

-------------------------------------------------------------------
-- 1C. Leverage Distribution Across All Trades
-- Overall split: how many trades used high risk vs low risk
-- crossed = True  → Cross Margin (high risk, no cap)
-- crossed = False → Isolated Margin (fixed risk, safer)
-------------------------------------------------------------------
SELECT
    Crossed   AS leverage_type,
    COUNT(*)  AS trade_count,
    cast(100.0 * COUNT(*) / SUM(COUNT(*)) OVER()as decimal(10, 2)) AS percent_of_total
FROM historical_data1
GROUP BY Crossed
ORDER BY trade_count DESC;

------------------------------------------------------------------
-- 1D. Number of Trades Per Day
-- Useful to spot if trading activity spikes on Fear days
------------------------------------------------------------------

SELECT 
	h.date       AS trade_date,
    f.classification,
    coalesce(sum(CASE WHEN h.side = 'sell' THEN 1 END),0 )          AS trades_per_day
FROM historical_data1 h
JOIN fear_greed_index_ f ON h.date = f.date
GROUP BY h.date, f.classification
ORDER BY trade_date;


--------------------------------------------------------
-- 1E. Long / Short Ratio with Sentiment and overview
-------------------------------------------------------
--a. Overview 
select side,
COUNT(*)tarde_per_count,
cast(COUNT(*)*100.0/SUM(COUNT(*)) over() AS decimal(10,2)) change_percentage  
from historical_Data1
group by Side

--b segregated sentiment wise

SELECT
f.classification,
CAST(100.0 * SUM(CASE WHEN h.side = 'buy'  THEN 1.0 ELSE 0.0 END) / COUNT(*) AS DECIMAL(10,2)) AS long_pct,
CAST(100.0 * SUM(CASE WHEN h.side = 'sell' THEN 1.0 ELSE 0.0 END) / COUNT(*) AS DECIMAL(10,2)) AS short_pct
FROM historical_data1 h
JOIN fear_greed_index_ f ON h.date = f.date
GROUP BY f.classification;

-- ================================================================
-- Part B: (Analysis)
--QUESTION 1 : Does Fear vs Greed affect trading performance?
--Insights : What this query does:
--   Compares how well traders performed under each sentiment.
--   It answers: On which sentiment days did traders earn more,
--   win more often, and lose less?
--
-- Columns explained:
--   total_trades      → how many trades were closed that day
--   total_pnl         → total money made across all trades
--   avg_pnl_per_trade → average earning per single trade
--                       (better for comparison than total_pnl
--                        because Fear has 3x more trades than
--                        Greed — total would be misleading)
--   win_rate_percent  → out of 100 trades, how many were profit
--   avg_loss_drawdown → when a trade lost money, how much did
--                       it lose on average — this is our proxy
--                       for risk. Lower number = more dangerous.
--
-- Why AVG and not SUM for losses:
--   Fear has 67,790 trades. Greed has 20,868.
--   If we summed losses, Fear would always look worse just
--   because it had more trades — not because it was riskier.
--   AVG gives a fair per-trade comparison across all groups.

-- ================================================================


select f.classification as sentiments,format(COUNT(*),'N2')  as total_trades, 
round(SUM(h.Closed_PnL),2) as total_pnl,
round(avg(h.Closed_PnL),2) as avg_pnl_per_trade,
CAST(SUM(CASE WHEN h.Closed_PnL>0 THEN 1 ELSE 0 END)*100/COUNT(*) AS DECIMAL(10,2)) AS win_rate_percent,
cast(AVG(case when h.Closed_PnL<0 then h.Closed_PnL end) AS decimal(10,2))  as avg_loss_drawdown

from historical_data1 h join fear_greed_index_ f on H.date=f.date where h.Side='SELL'
group by f.classification  order by total_pnl desc


-- ================================================================
--  QUESTION 2
-- Do traders change behavior based on sentiment?

-- What this query does:
--   Looks at HOW traders behaved under each sentiment — not just
--   how they performed. It answers: did they trade more often?
--   Did they bet bigger? Did they take more risk?
--
-- Columns explained:
--   trade_frequency   → total number of closed trades per sentiment
--                       high number = traders were very active
--   avg_position_size → average dollar size of each trade
--                       high number = traders were betting big
--   long_bias_pct     → % of trades that were BUY (going long)
--   short_bias_pct    → % of trades that were SELL (going short)
--                       these two always add up to 100%
--   cross_margin_pct  → % of trades using cross margin (high risk)
--                       high number = traders were taking more risk
--
-- Important note on why there is no WHERE filter here:
--   long_bias_pct needs to count BUY rows. If we added
--   WHERE side = 'sell', all BUY rows would disappear and
--   long_bias_pct would show 0% for everything. So instead,
--   each column filters itself using CASE WHEN inside.
-- ---------------------------------------------------------
-- ================================================================

select f.classification as sentiments,
sum(case when h.Side='Sell' then 1 else 0 end ) as trade_frequency,
cast(AVG(case when h.Side='Sell' then h.Size_USD end ) As decimal(10,2)) AS avg_position_size,
cast(sum(case when h.Side='Buy' then 1 else 0 end)*100.0/COUNT(*) as decimal(10,2)) as long_bias_precent,
cast(sum(case when h.Side='Sell' then 1 else 0 end)*100.0/COUNT(*) as decimal(10,2)) as Short_bias_precent,
cast(100.0 * SUM(CASE WHEN h.Crossed = 'True' THEN 1.0 ELSE 0.0 END) / COUNT(*)AS decimal(10, 2)) AS cross_margin_pct
from historical_data1 h join fear_greed_index_ f on H.date=f.date 
group by f.classification 
order by trade_frequency desc

--QUESTION 3 — TRADER SEGMENTATION

-- Segment A: High Leverage vs Low Leverage
--Not all traders take the same risk. This splits trades into two groups to see if high risk traders actually earn more 
--or end up performing worse than cautious traders.

select   
CASE WHEN crossed = 'True' THEN 'High Leverage' ELSE 'Low Leverage' END   AS leverage_segment,
count(case when side='sell' then 1 end) as trade_count,
cast(avg(case when side='sell' then closed_Pnl end) as decimal(10,2)) as avg_pnl,
cast(SUM(CASE WHEN Side='SELL' AND Closed_PnL> 0  THEN 1 ELSE 0 END)*100.0
/ COUNT(CASE WHEN side='SELL' THEN 1 END)as decimal(10,2))    AS win_rate_pct
from historical_data1 group by crossed

-- Segment B: Frequent vs Infrequent Traders
--Do traders who trade more earn more per trade? Or do selective traders with fewer trades do better? 
--Threshold = 3,000 based on average trade count. Two-level AVG used so big accounts do not dominate.

with trader_segment as(
select account,
count(*) as total_trade,cast(avg(closed_pnl) as decimal(10,2))as avg_pnl 
from historical_data1 where side='sell' group by account)

select 
case when total_trade>3000 then 'Frequent_trader' else 'Infrequent_trader' end as trader_segment,
count(*),avg(avg_pnl) as avg_pnl_per_trade 
from trader_segment
group by case when total_trade>3000 then 'Frequent_trader' else 'Infrequent_trader' end


--Identifies which accounts win reliably above 55% of the time versus those who win unpredictably. 
--Shows how many traders fall into each group.

with trader_status as(

select account,
count(1) total_trades,
cast(sum(case when closed_pnl>0 then 1 else 0 end)*100.0/ count(*) as decimal(10,2)) as win_rate
from historical_data1  where side ='sell'group by account )

select case when win_rate>55 then 'consitent_trader' else 'Inconsistent_trader' end as trader_segment,
count(*) as num_trader,
cast(AVG(win_rate)as decimal(20,2)) as avg_win_rate 
from trader_status 
group by (case when win_rate>55 then 'consitent_trader' else 'Inconsistent_trader' end)













