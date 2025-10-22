import os
import pandas as pd
import numpy as np
from snowflake import connector
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
# ---- Snowflake connection (use env vars in real life) ----
conn = connector.connect(
    account="ds62165.us-east-2.aws",   # or the short form 'ds62165'
    user="SAHITHIV",
    password=os.getenv("SNOWFLAKE_PWD"),  # set this in your env!
    warehouse="COMPUTE_WH",
    database="CUSTOMER_ANALYTICS",
    schema="MARTS",
    role="ACCOUNTADMIN",
)

# ---- 1) Pull features from your fact table ----
q = """
SELECT customer_id, recency_days, frequency, monetary
FROM CUSTOMER_ANALYTICS.MARTS.FCT_RFM
WHERE recency_days IS NOT NULL
  AND frequency IS NOT NULL
  AND monetary  IS NOT NULL
"""
df = pd.read_sql(q, conn)
df.columns = [c.lower() for c in df.columns]

X = df[['recency_days','frequency','monetary']].copy()

X['monetary'] = np.log(X['monetary'] + 1)

# ---- 2) Scale features ----
scaler = StandardScaler()
Xs = scaler.fit_transform(X)

# ---- 3) Pick K via silhouette (quick heuristic) ----
best_k, best_score, best_model = None, -1, None
for k in [3,4,5,6]:
    km = KMeans(n_clusters=k, n_init=20, random_state=42)
    labels = km.fit_predict(Xs)
    score = silhouette_score(Xs, labels)
    if score > best_score:
        best_k, best_score, best_model = k, score, km

labels = best_model.labels_

# ---- 4) Prepare results and write back ----
out = df[['customer_id']].copy()
out['cluster_id'] = labels  # 0..K-1

# Create a small “profile” per cluster (optional, useful for docs)
centers = pd.DataFrame(best_model.cluster_centers_, columns=X.columns)
centers[['recency_days','frequency','monetary']] = scaler.inverse_transform(centers)

# Write labels to Snowflake (replace table)
cur = conn.cursor()
cur.execute("""
    CREATE OR REPLACE TABLE CUSTOMER_ANALYTICS.MARTS.CUSTOMER_CLUSTERS (
        CUSTOMER_ID VARCHAR,
        CLUSTER_ID  INTEGER
    )
""")

# efficient write (executemany)
rows = list(out.itertuples(index=False, name=None))
cur.executemany(
    "INSERT INTO CUSTOMER_ANALYTICS.MARTS.CUSTOMER_CLUSTERS (CUSTOMER_ID, CLUSTER_ID) VALUES (%s, %s)",
    rows
)

conn.commit()
cur.close()
conn.close()

print(f"Done. Best K = {best_k}, silhouette = {best_score:.3f}")
