"""
load.py — load the CSVs into PostgreSQL.
"""
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

DATA_DIR = Path(os.getenv("DATA_DIR", "data"))

engine = create_engine(
    f"postgresql+psycopg2://{os.environ['DB_USER']}:{os.environ['DB_PASSWORD']}"
    f"@{os.environ['DB_HOST']}:{os.environ['DB_PORT']}/{os.environ['DB_NAME']}"
)

SPECS = [
    ("category_name_translation", "category_translation", [], []),
    ("sellers_dataset",           "sellers",              [], []),
    ("products_dataset",          "products",             [],
        ["product_name_lenght", "product_description_lenght", "product_photos_qty",
         "product_weight_g", "product_length_cm", "product_height_cm", "product_width_cm"]),
    ("customers_dataset",         "customers",            [], []),
    ("orders_dataset",            "orders",
        ["order_purchase_timestamp", "order_approved_at", "order_delivered_carrier_date",
         "order_delivered_customer_date", "order_estimated_delivery_date"], []),
    ("order_items_dataset",       "order_items",    ["shipping_limit_date"], []),
    ("order_payments_dataset",    "order_payments", [], []),
    ("order_reviews_dataset",     "order_reviews",
        ["review_creation_date", "review_answer_timestamp"], []),
    ("geolocation_dataset",       "geolocation",    [], []),  
]

def find_csv(suffix: str) -> Path:
    matches = sorted(DATA_DIR.glob(f"*{suffix}.csv"))
    if not matches:
        raise FileNotFoundError(f"No CSV ending in '{suffix}.csv' under {DATA_DIR}/")
    return matches[0]


def load_one(suffix, table, date_cols, int_cols):
    df = pd.read_csv(find_csv(suffix), parse_dates=date_cols or None)
    for col in int_cols:
        df[col] = df[col].astype("Int64")   

    chunksize = max(1, 65000 // len(df.columns))
    df.to_sql(table, engine, if_exists="append", index=False,
              chunksize=chunksize, method="multi")
    print(f"  {table:<22} {len(df):>9,} rows")


if __name__ == "__main__":
    print(f"Loading Olist CSVs from {DATA_DIR}/ (run schema.sql first)\n")
    for spec in SPECS:
        load_one(*spec)

    print("\nRow counts in the database:")
    with engine.connect() as conn:
        for _, table, _, _ in SPECS:
            n = conn.execute(text(f"SELECT count(*) FROM {table}")).scalar()
            print(f"  {table:<22} {n:>9,}")
    print("\nDone.")
