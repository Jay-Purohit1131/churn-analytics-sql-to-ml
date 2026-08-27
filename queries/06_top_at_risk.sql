SELECT
    customer_unique_id,
    round(churn_risk_score::numeric, 3) AS churn_risk_score,
    scored_at
FROM predictions
ORDER BY churn_risk_score DESC
LIMIT 100