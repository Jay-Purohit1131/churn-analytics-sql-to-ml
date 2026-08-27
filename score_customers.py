import joblib
import pandas as pd
from datetime import datetime 
from db import run_query, engine

rf = joblib.load("models/churn_model.pkl")

df = run_query("SELECT * FROM feature_view")
df['has_review'] = df['avg_review_score'].notna().astype(int)
df['avg_review_score'] = df['avg_review_score'].fillna(df['avg_review_score'].median())

ids = df['customer_unique_id']
X = df.drop(columns=['customer_unique_id', 'is_churned', 'recency'])

risk_scores = rf.predict_proba(X)[:,1]

predictions = pd.DataFrame({
    'customer_unique_id': ids,
    'churn_risk_score': risk_scores,
    'scored_at': datetime.now()
})
print(predictions.head())

predictions.to_sql('predictions', engine, if_exists='replace', index=False)
print(f"Wrote {len(predictions)} risk scores to predictions table.")

