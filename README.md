churn-analytics-sql-to-ml

An end-to-end analytics-engineering pipeline on PostgreSQL — raw e-commerce data loaded into a proper multi-table schema, all analysis and feature engineering done in SQL inside the database, a churn model that reads those features via SQLAlchemy, and predictions written back into the database where they can be queried like any other table.

The defining idea is a closed loop:

data in → analysis in SQL → features in SQL → model in Python → predictions back into SQL → surfaced by SQL

You work where the data actually lives, not in an isolated notebook.

Stakeholder question

An e-commerce business is losing customers to inactivity. Which cohorts stop coming back, why, and which customers are most at risk of not purchasing again — answered live from the database, not a flat CSV?

Dataset — Olist Brazilian E-Commerce

The Olist public dataset: ~100k orders placed 2016–2018, spread across multiple relational tables (orders, order items, customers, payments, reviews, products, sellers). Chosen over Telco Churn because its real timestamps and transactions are what make cohort retention and RFM possible.

Defining churn: Olist has no subscription and no built-in churn label, so churn is defined here as a customer with no order within N days of a snapshot date. (Note: Olist skews heavily toward one-time buyers — the repeat-purchase rate is low — which is itself part of the retention story this project surfaces.)

Stack

PostgreSQL · SQL (CTEs, window functions) · SQLAlchemy · pandas · scikit-learn Tooling: Docker, git/GitHub, dbdiagram.io (schema diagram)

Planned repo structure
churn-analytics-sql-to-ml/
├── data/            # raw Olist CSVs (git-ignored)
├── sql/
│   ├── schema.sql   # DDL: tables, primary/foreign keys, constraints
│   └── load.py      # staging load → normalised tables
├── queries/         # 10+ documented .sql files, one business question each
├── db.py            # SQLAlchemy engine + run_query(sql) -> DataFrame
├── pipeline.py      # feature view → model → write predictions back
├── docs/            # data dictionary, schema diagram (PNG)
├── requirements.txt
├── .env.example     # DB connection template (never commit real .env)
└── README.md
Getting started

Prerequisites: Python 3.10+ and PostgreSQL (Docker is fastest).

bash
# 1. Clone
git clone https://github.com/<you>/churn-analytics-sql-to-ml.git
cd churn-analytics-sql-to-ml

# 2. Postgres via Docker
docker run --name churn-pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres

# 3. Python environment
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt        # sqlalchemy, psycopg2-binary, pandas, scikit-learn, jupyter

# 4. Configure the connection
cp .env.example .env                    # then edit with your DB credentials

# 5. Create the database and confirm you can connect
psql -h localhost -U postgres -c "CREATE DATABASE olist;"

Schema creation, data load, and the pipeline run will be documented here as they land.

Status
🚧 In progress. Environment and database are set up; building the schema and load next.