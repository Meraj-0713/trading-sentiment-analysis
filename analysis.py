# ================================================================
# PROJECT  : Trading Behavior & Sentiment Analysis
# AUTHOR   : [Your Name]
# DATE     : May 2026
# TOOL     : Python (pandas)
# ================================================================
# PURPOSE:
#   This script loads and validates the two datasets used in the
#   SQL analysis. It checks data quality (shape, duplicates,
#   missing values) and converts Unix timestamps into readable
#   date format so they can be joined with the sentiment index.
# ================================================================

import pandas as pd

# ----------------------------------------------------------------
# LOAD DATASETS
# Place both CSV files in the same folder as this script.
# Update filenames below if yours are named differently.
# ----------------------------------------------------------------
historical_data    = pd.read_csv("historical_data.csv")
fear_greed_index   = pd.read_csv("fear_greed_index_.csv")


# ================================================================
# SECTION 1: DATA QUALITY CHECK
# ================================================================

# ----------------------------------------------------------------
# Dataset 1 — Historical Trading Data
# Shows shape, duplicate rows, and any missing values
# so we know the data is clean before running any analysis.
# ----------------------------------------------------------------
print("=" * 50)
print("DATASET 1 — Historical Trading Data")
print("=" * 50)
print(f"Rows        : {historical_data.shape[0]}")
print(f"Columns     : {historical_data.shape[1]}")
print(f"Duplicates  : {historical_data.duplicated().sum()}")
print("\nMissing Values per Column:")
print(historical_data.isnull().sum())
print()


# ----------------------------------------------------------------
# Dataset 2 — Fear & Greed Index
# Same check on the sentiment dataset.
# Duplicates here would mean two sentiment values for one day
# which would cause wrong results in the SQL JOIN.
# ----------------------------------------------------------------
print("=" * 50)
print("DATASET 2 — Fear & Greed Index")
print("=" * 50)
print(f"Rows        : {fear_greed_index.shape[0]}")
print(f"Columns     : {fear_greed_index.shape[1]}")
print(f"Duplicates  : {fear_greed_index.duplicated().sum()}")
print("\nMissing Values per Column:")
print(fear_greed_index.isnull().sum())
print("=" * 50)


# ================================================================
# SECTION 2: TIMESTAMP CONVERSION
# ================================================================

# ----------------------------------------------------------------
# The timestamp column in both datasets is stored as Unix time —
# number of seconds elapsed since January 1, 1970.
# Example: 1609459200 = 2021-01-01
#
# pd.to_datetime(..., unit='s') converts this into a real date.
# We then extract just the date part (no time) using .dt.date
# so it can be matched with the sentiment index date column
# in SQL using: CAST(h.time AS DATE) = f.date
# ----------------------------------------------------------------

# Convert Fear & Greed timestamp
fear_greed_index['timestamp'] = pd.to_datetime(
    fear_greed_index['timestamp'], unit='s'
)
fear_greed_index['date'] = fear_greed_index['timestamp'].dt.date

# Convert Historical Data timestamp
historical_data['timestamp'] = pd.to_datetime(
    historical_data['timestamp'], unit='s'
)
historical_data['date'] = historical_data['timestamp'].dt.date


# ----------------------------------------------------------------
# Quick check — show first 5 rows of each to confirm conversion
# ----------------------------------------------------------------
print("\nFear & Greed Index — after timestamp conversion:")
print(fear_greed_index[['timestamp', 'date', 'value', 'value_classification']].head())

print("\nHistorical Data — after timestamp conversion:")
print(historical_data[['timestamp', 'date']].head())
