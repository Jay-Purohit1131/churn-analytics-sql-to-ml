# Data Dictionary — Olist E-Commerce Database

Source: Olist Brazilian E-Commerce public dataset (~100k orders, 2016–2018).
Nine tables loaded into PostgreSQL. Analysis population is **delivered orders only**
unless stated otherwise.

---

## customers
One row per `customer_id`. **Key quirk:** `customer_id` is unique *per order*;
`customer_unique_id` identifies the real person across orders. All cohort / RFM /
churn analysis keys on `customer_unique_id`.

| Column | Type | Description |
|---|---|---|
| customer_id | TEXT (PK) | Per-order customer identifier; joins to `orders.customer_id`. |
| customer_unique_id | TEXT | The real customer across orders. Use this for person-level analysis. |
| customer_zip_code_prefix | INTEGER | First 5 digits of the customer's ZIP code. |
| customer_city | TEXT | Customer city. |
| customer_state | CHAR(2) | Two-letter Brazilian state code (e.g. SP, RJ). |

---

## orders
One row per order. Central fact table; ~99,441 rows.
**Notes:** delivery-date columns are NULL for orders that were cancelled or never
delivered (~2,965 null `order_delivered_customer_date`).

| Column | Type | Description |
|---|---|---|
| order_id | TEXT (PK) | Unique order identifier. |
| customer_id | TEXT (FK) | References `customers.customer_id`. |
| order_status | TEXT | delivered, shipped, canceled, unavailable, etc. |
| order_purchase_timestamp | TIMESTAMP | When the order was placed. No nulls; spans 2016–2018. |
| order_approved_at | TIMESTAMP | Payment approval time (160 nulls). |
| order_delivered_carrier_date | TIMESTAMP | Handed to carrier (1,783 nulls). |
| order_delivered_customer_date | TIMESTAMP | Delivered to customer (2,965 nulls). |
| order_estimated_delivery_date | TIMESTAMP | Estimated delivery date. |

---

## order_items
One row per **item within** an order. Composite key `(order_id, order_item_id)`.
**Note:** `price` and `freight_value` are per item, so an order's total value is the
sum across all its item rows — an order with 3 items has 3 rows here.

| Column | Type | Description |
|---|---|---|
| order_id | TEXT (PK, FK) | References `orders.order_id`. |
| order_item_id | INTEGER (PK) | Sequence number of the item within the order (1, 2, 3…). |
| product_id | TEXT (FK) | References `products.product_id`. |
| seller_id | TEXT (FK) | References `sellers.seller_id`. |
| shipping_limit_date | TIMESTAMP | Seller's deadline to hand the item to the carrier. |
| price | NUMERIC(10,2) | Item price (per item, excludes freight). |
| freight_value | NUMERIC(10,2) | Shipping cost for this item. |

---

## order_payments
One row per **payment installment**. Composite key `(order_id, payment_sequential)`.
**Note:** an order can have multiple payment rows (e.g. split across methods or
installments), so joining this to orders can multiply order rows.

| Column | Type | Description |
|---|---|---|
| order_id | TEXT (PK, FK) | References `orders.order_id`. |
| payment_sequential | INTEGER (PK) | Sequence of the payment within the order. |
| payment_type | TEXT | credit_card, boleto, voucher, debit_card, etc. |
| payment_installments | INTEGER | Number of installments chosen. |
| payment_value | NUMERIC(10,2) | Value of this payment. |

---

## order_reviews
One row per review. Uses a surrogate key `review_pk`.
**Key quirks:** `review_id` is **not unique** (~800 duplicates in the raw data), which
is why a surrogate primary key was added. The comment title/message columns are
**heavily null** — most customers give a star rating without writing text.

| Column | Type | Description |
|---|---|---|
| review_pk | BIGSERIAL (PK) | Surrogate key (auto-generated); `review_id` alone isn't unique. |
| review_id | TEXT | Original review identifier (may repeat across rows). |
| order_id | TEXT (FK) | References `orders.order_id`. |
| review_score | INTEGER | Rating, 1–5. |
| review_comment_title | TEXT | Optional review title (mostly NULL). |
| review_comment_message | TEXT | Optional review body (mostly NULL). |
| review_creation_date | TIMESTAMP | When the review survey was sent. |
| review_answer_timestamp | TIMESTAMP | When the customer submitted the review. |

---

## products
One row per product. ~32,951 rows.
**Key quirks:** `product_name_lenght` and `product_description_lenght` keep the
**original misspelling** from the source data. `product_category_name` is in
Portuguese (join to `category_translation` for English) and has some nulls; the
measurement columns also contain nulls.

| Column | Type | Description |
|---|---|---|
| product_id | TEXT (PK) | Unique product identifier. |
| product_category_name | TEXT | Category in Portuguese; soft link to `category_translation` (some nulls). |
| product_name_lenght | INTEGER | Character length of the product name (sic: misspelled). |
| product_description_lenght | INTEGER | Character length of the description (sic: misspelled). |
| product_photos_qty | INTEGER | Number of product photos. |
| product_weight_g | INTEGER | Product weight in grams. |
| product_length_cm | INTEGER | Package length in cm. |
| product_height_cm | INTEGER | Package height in cm. |
| product_width_cm | INTEGER | Package width in cm. |

---

## sellers
One row per seller. ~3,095 rows. Straightforward reference table.

| Column | Type | Description |
|---|---|---|
| seller_id | TEXT (PK) | Unique seller identifier. |
| seller_zip_code_prefix | INTEGER | First 5 digits of the seller's ZIP code. |
| seller_city | TEXT | Seller city. |
| seller_state | CHAR(2) | Two-letter Brazilian state code. |

---

## category_translation
Lookup table mapping Portuguese category names to English. ~71 rows.
**Note:** two categories present in `products` (`pc_gamer`,
`portateis_cozinha_e_preparadores_de_alimentos`) are **missing** from this table —
that's why the link from `products` is a soft join, not an enforced foreign key.

| Column | Type | Description |
|---|---|---|
| product_category_name | TEXT (PK) | Category name in Portuguese. |
| product_category_name_english | TEXT | Category name in English. |

---

## geolocation
Reference table of ZIP-code-prefix coordinates. ~1,000,163 rows.
**Key quirks:** the ZIP prefix is **not unique** (many lat/lng rows per prefix), so
this table has no primary key and no foreign keys. Not used in the core churn
analysis; loaded for completeness / optional geographic work.

| Column | Type | Description |
|---|---|---|
| geolocation_zip_code_prefix | INTEGER | First 5 digits of a ZIP code (not unique). |
| geolocation_lat | DOUBLE PRECISION | Latitude. |
| geolocation_lng | DOUBLE PRECISION | Longitude. |
| geolocation_city | TEXT | City name. |
| geolocation_state | CHAR(2) | Two-letter Brazilian state code. |