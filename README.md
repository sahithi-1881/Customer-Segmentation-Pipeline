
# 🧩 Customer Segmentation & Behavior Analysis

This project implements an **end-to-end customer segmentation pipeline** using **Snowflake**, **dbt**, and **Python (KMeans clustering)**.  
It transforms raw online retail transactions into clean, feature-engineered datasets and then groups customers based on purchasing behavior.


## 🧠 Project Overview

The goal was to identify and understand customer purchasing behavior by analyzing how recently, how often, and how much customers spend.  
Using **RFM (Recency, Frequency, Monetary)** metrics and **KMeans clustering**, customers were categorized into segments such as *Champions*, *Potential Loyalists*, and *At-Risk*.

### ✅ Workflow Summary
1. **Data Cleaning & Transformation (dbt)**
   - Loaded raw data into Snowflake.
   - Created a staging model (`stg_online_retail.sql`) to clean and format data — removing nulls, filtering cancellations, and converting timestamps.
2. **Feature Engineering (RFM Calculation)**
   - Built a dbt model (`fct_rfm.sql`) to compute Recency, Frequency, and Monetary metrics for each customer.
3. **Scoring & Segmentation**
   - Assigned R, F, M scores (1–5) in dbt.
   - Combined scores into an `rfm_code` to derive segments such as *Champions*, *Loyal*, and *Potential*.
4. **KMeans Clustering (Python)**
   - Connected Python to Snowflake using `snowflake-connector-python`.
   - Pulled RFM metrics from `CUSTOMER_ANALYTICS.MARTS.FCT_RFM`.
   - Applied **KMeans clustering** to form 3 customer groups based on RFM similarity.
   - Wrote results back to Snowflake as `CUSTOMER_CLUSTERS`.
5. **Behavioral Insights**
   - Calculated average Recency, Frequency, and Monetary values by cluster.
   - Interpreted segments:
     - **Cluster 0** → High Frequency & Spending = Champions  
     - **Cluster 1** → Low Frequency & Low Spending = At-Risk  
     - **Cluster 2** → Moderate Frequency & Spending = Potential Loyalists



## 🧱 Tech Stack

| Layer | Tool / Library |
|-------|----------------|
| Data Warehouse | **Snowflake** |
| Data Transformation | **dbt-core**, **dbt-snowflake** |
| Modeling / ML | **Python**, **pandas**, **scikit-learn** |
| Visualization | **Tableau** |




