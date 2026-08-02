# churn-analytics-sql-to-ml

An end-to-end analytics-engineering pipeline: a real PostgreSQL database with a
proper multi-table schema, analytical SQL (window functions, CTEs, cohort/retention
analysis), features engineered in SQL and fed via SQLAlchemy into a churn model
whose predictions are written back into the database.

**Stakeholder question:** A subscription/e-commerce business is losing customers.
Which cohorts churn, why, and which current customers are about to leave —
pulled live from the warehouse, not a CSV?

## Status
🚧 In progress.

## Stack
PostgreSQL · SQL (CTEs, window functions) · SQLAlchemy · pandas · scikit-learn
