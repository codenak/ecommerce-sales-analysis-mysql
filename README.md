# E-Commerce Sales & Customer Analysis
End-to-end data analysis project on a real-world e-commerce dataset using MySQL.

## Dataset
UCI Online Retail II — 640K+ rows of transactional data from a UK-based online retailer.  
Source: https://archive.ics.uci.edu/dataset/502/online+retail+ii

## What this project covers

### Phase 1 — Data Cleaning
- Removed cancelled orders (Invoice starting with 'C')
- Resolved NULL CustomerIDs and Descriptions
- Removed negative and zero Quantity/Price rows
- Fixed carriage return encoding errors affecting 400K+ rows (identified using HEX())
- Added calculated TotalPrice column

### Phase 2 — Exploratory Analysis
- Monthly revenue trend
- Top 10 best-selling products by units sold
- Top 10 countries by revenue
- Average order value

### Phase 3 — Advanced Analysis
- Month-over-month revenue growth using LAG()
- Top 3 products per country using RANK()
- RFM customer segmentation (Recency, Frequency, Monetary) using CTEs
- Repeat vs one-time customer ratio

### Phase 4 — Stored Procedure
- Reusable procedure that accepts a country name and returns top 5 customers by revenue

## Key Techniques
CTEs, Window Functions (RANK, LAG, ROW_NUMBER), Subqueries, Stored Procedures, LOAD DATA INFILE, HEX() for encoding diagnosis

## Tools
MySQL Workbench
