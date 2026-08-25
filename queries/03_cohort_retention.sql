-- ============================================================================
-- Cohort Retention Analysis
-- ----------------------------------------------------------------------------
-- Business question: Of the customers who first purchased in a given month,
-- what percentage placed another order N months later?
--
-- Output is "long" format: one row per (cohort, months_since) cell. Pivoted
-- into the retention triangle (cohorts × months-since) in pandas for the heatmap.
-- Churn context: Olist is a one-time-purchase marketplace (~3% repeat rate),
-- so retention collapses from 100% to <1% after month 0 — a cliff, not a decay.
-- All logic keyed on customer_unique_id; delivered orders only.
-- ============================================================================

WITH cohort AS (
    -- Step 1 — Cohort assignment.
    -- One row per customer, tagged with the MONTH of their first delivered order.
    -- date_trunc('month', ...) collapses the exact timestamp to the 1st of the
    -- month so all customers who first bought in e.g. March 2017 share a cohort.
    -- cohort_date is the real date (used for sorting/joining); cohort_month is a
    -- readable text label for display only.

    SELECT
        c.customer_unique_id,
        date_trunc('month', min(o.order_purchase_timestamp)) AS cohort_date,
        to_char(min(o.order_purchase_timestamp), 'Month YYYY') AS cohort_month
    FROM orders AS o
    INNER JOIN customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
orders_with_cohort AS (
    -- Step 2 — Position every order on the retention timeline.
    -- Join each delivered order back to its customer's cohort, then compute
    -- months_since: how many whole months after the cohort month the order
    -- occurred. Formula = (year diff * 12) + (month diff). A customer's first
    -- order is month 0; an order two months later is month 2.
    SELECT
        ch.customer_unique_id,
        ch.cohort_date,
        ch.cohort_month,
        (date_part('year',  o.order_purchase_timestamp) - date_part('year',  ch.cohort_date)) * 12
      + (date_part('month', o.order_purchase_timestamp) - date_part('month', ch.cohort_date)) AS months_since
    FROM orders AS o
    INNER JOIN customers AS c   ON c.customer_id = o.customer_id
    INNER JOIN cohort AS ch     ON ch.customer_unique_id = c.customer_unique_id
    WHERE o.order_status = 'delivered'
),
cohort_counts AS (
    -- Step 3 — The body of the matrix.
    -- For each (cohort, months_since) cell, count how many DISTINCT customers
    -- were active. DISTINCT matters: a customer who placed 3 orders in the same
    -- month should count once (we're measuring "was this customer active?",
    -- not "how many orders did they place").

    SELECT
        cohort_date,
        months_since,
        count(DISTINCT customer_unique_id) AS active_customers
    FROM orders_with_cohort
    GROUP BY cohort_date, months_since
),
cohort_size AS (
    -- Step 4 — The denominator.
    -- Each cohort's original size = its active count at months_since = 0
    -- (everyone is active in their own signup month). Reused from cohort_counts
    -- rather than recomputed.

    SELECT 
        cohort_date, 
        active_customers AS cohort_n
    FROM cohort_counts
    WHERE months_since = 0
)
-- Final step — Retention percentages.
-- Join each cell's active count to its cohort's original size and compute
-- % retained. months_since = 0 is always 100% (the baseline). Ordered by the
-- real date so cohorts come out chronologically, not alphabetically.

SELECT
    cc.cohort_date,
    to_char(cc.cohort_date, 'FMMonth YYYY') AS cohort,
    cc.months_since,
    cc.active_customers,
    cs.cohort_n,
    round(100.0 * cc.active_customers / cs.cohort_n, 2) AS pct_retained
FROM cohort_counts AS cc
INNER JOIN cohort_size AS cs ON cs.cohort_date = cc.cohort_date
ORDER BY cc.cohort_date, cc.months_since;

