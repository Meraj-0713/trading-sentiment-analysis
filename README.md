# trading-sentiment-analysis
Analysis of Fear &amp; Greed market sentiment vs trading performance

# Trading Behavior & Sentiment Analysis

An end-to-end data analysis project exploring whether market sentiment —
Fear, Greed, Neutral, and Extreme Greed — influences trader performance
and behavior using real historical trading data.

***

## Project Structure

```
trading-sentiment-analysis/
├── analysis.sql        # All SQL queries — key metrics, analysis, segmentation, strategies
├── analysis.py         # Python script — data loading, quality check, timestamp conversion
├── charts/             # Output charts exported from Power BI
└── README.md           # This file
```

***

## Datasets Used

| Dataset | Description |
|---|---|
| `historical_data.csv` | Raw trade-level data — account, timestamp, side, PnL, size, leverage |
| `fear_greed_index_.csv` | Daily Fear & Greed sentiment index — date, value, sentiment label |

**Join logic:** Every trade is matched to the sentiment of its trading day using
`CAST(timestamp AS DATE) = sentiment_date`

***

## How to Run

### SQL (SQL Server)
1. Import both CSV files into SQL Server as tables:
   - `historical_data1`
   - `fear_greed_index`
2. Open `analysis.sql` in SSMS (SQL Server Management Studio)
3. Run each section top to bottom — sections are clearly labeled

### Python
1. Install dependency:
   ```
   pip install pandas
   ```
2. Place both CSV files in the same folder as `analysis.py`
3. Run the script:
   ```
   python analysis.py
   ```
4. Output will show dataset shape, duplicates, missing values,
   and a preview of the converted date columns

***

## Methodology

- **Data Source:** Historical perpetual futures trading data joined with the
  daily Fear & Greed Index
- **Join Key:** Trade date matched to sentiment date
- **PnL Logic:** Only SELL rows are used for PnL since each trade has two rows —
  BUY (entry) and SELL (exit). PnL is only recorded at exit.
- **Drawdown Proxy:** Average loss per trade used as a drawdown proxy since
  peak-to-trough balance data is unavailable
- **Segmentation Threshold:** Traders with >3,000 trades labelled Frequent;
  accounts with ≥55% win rate labelled Consistent Winners
- **Tools Used:** SQL Server (SQL), Python (pandas), Power BI

***

## Key Insights

### Question 1 — Does sentiment affect performance?
- **Extreme Greed** produced the highest avg PnL per trade ($286) and
  the best win rate (65%) — the most profitable sentiment to trade in
- **Greed** also performed well with 61% win rate and $143 avg PnL per trade
- **Neutral** was the most dangerous — only 24% win rate and -$1,198 avg loss
- **Fear** had the highest trade volume (67,790 trades) but average PnL
  was low ($42) and losses were deeper than Greed days

### Question 2 — Do traders change behavior based on sentiment?
- Traders were significantly more active on Fear days — 3x more trades
  than Greed days, suggesting emotional overtrading during market panic
- Position sizes were larger on Greed days, meaning traders bet bigger
  when the market was optimistic
- Cross margin (high leverage) usage was highest on Fear days — the worst
  possible time to take on maximum risk

### Question 3 — Trader Segmentation
- **High Leverage traders** had lower avg PnL and lower win rate than
  Low Leverage traders — more risk did not mean more reward
- **Frequent Traders** (>3,000 trades) showed lower avg PnL per trade
  than Infrequent Traders — overtrading hurt performance
- **Consistent Winners** (≥55% win rate) made up a small portion of accounts
  but maintained disciplined win rates across all sentiment conditions

***

## Strategy Recommendations

### Strategy 1 — Trade on Greed, Sit Out on Neutral
> Greed and Extreme Greed days produced 61–65% win rates.
> Neutral days produced only 24% win rate with extreme avg losses (-$1,198).
> **Rule:** Prioritise entering new positions on Greed days.
> Reduce or pause trading entirely on Neutral sentiment days.

### Strategy 2 — Reduce Leverage on Fear Days
> Fear days already had lower PnL quality ($42 avg per trade).
> Traders who used high leverage (cross margin) on Fear days
> amplified their losses further.
> **Rule:** Switch to isolated margin (low leverage) on Fear days.
> High leverage should only be used on confirmed Greed sentiment.

***

## Author

**[Meraj Ahmed]**  
Data Analysis Project — May 2026
