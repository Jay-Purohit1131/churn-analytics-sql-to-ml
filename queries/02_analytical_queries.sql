

--Q1
WITH snapshot AS (
    SELECT max(order_purchase_timestamp) AS snap_date FROM orders
),
customer_status AS (
    SELECT
        c.customer_unique_id,
        max(o.order_purchase_timestamp) AS last_order,
        CASE WHEN max(o.order_purchase_timestamp)
                  < (SELECT snap_date FROM snapshot) - interval '180 days'
             THEN 1 ELSE 0 END AS is_churned
    FROM orders AS o
    INNER JOIN customers AS c
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    count(*) AS total_customers,
    sum(is_churned) AS churned,
    round(100.0 * sum(is_churned) / count(*), 2) AS churn_rate
FROM customer_status;

--Q2
WITH snapshot AS (
    SELECT max(order_purchase_timestamp) AS snap_date FROM orders
),
customer_status AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        max(o.order_purchase_timestamp) AS last_order,
        CASE WHEN max(o.order_purchase_timestamp)
                  < (SELECT snap_date FROM snapshot) - interval '180 days'
             THEN 1 ELSE 0 END AS is_churned
FROM orders AS o
INNER JOIN customers AS c
ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id,c.customer_state
) 
SELECT
    customer_state,
    count(*) AS total_customers,
    sum(is_churned) AS churned,
    round(100.0 * sum(is_churned) / count(*), 2) AS churn_rate
FROM customer_status
GROUP BY customer_state
ORDER BY churn_rate DESC;

--Q3
WITH snapshot AS (
    SELECT max(order_purchase_timestamp) AS snap_date FROM orders
),
customer_status AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        min(o.order_purchase_timestamp) AS first_order,
        CASE WHEN max(o.order_purchase_timestamp)
                  < (SELECT snap_date FROM snapshot) - interval '180 days'
             THEN 1 ELSE 0 END AS is_churned
FROM orders AS o
INNER JOIN customers AS c
ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id,c.customer_state
) 
SELECT
    date_trunc('month', first_order) AS cohort_month,
    count(*) AS total_customers,
    sum(is_churned) AS churned,
    round(100.0 * sum(is_churned) / count(*), 2) AS churn_rate
FROM customer_status
GROUP BY date_trunc('month', first_order)
ORDER BY cohort_month;

--Q4
WITH snapshot AS (
    SELECT max(order_purchase_timestamp) AS snap_date FROM orders
),
customer_status AS (
    SELECT
        c.customer_unique_id,
        p.payment_type,
        CASE WHEN max(o.order_purchase_timestamp)
                  < (SELECT snap_date FROM snapshot) - interval '180 days'
             THEN 1 ELSE 0 END AS is_churned
    FROM orders AS o
    INNER JOIN customers AS c      ON c.customer_id = o.customer_id
    INNER JOIN order_payments AS p ON p.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, p.payment_type
)
SELECT
    payment_type,
    count(*) AS total_customers,
    sum(is_churned) AS churned,
    round(100.0 * sum(is_churned) / count(*), 2) AS churn_rate
FROM customer_status
GROUP BY payment_type
ORDER BY churn_rate DESC;

--Q5 
WITH snapshot AS (
    SELECT max(order_purchase_timestamp) AS snap_date FROM orders
),
customer_status AS (
    SELECT
        c.customer_unique_id,
        sum(oi.price + oi.freight_value) AS total_spend,
        CASE WHEN max(o.order_purchase_timestamp)
                  < (SELECT snap_date FROM snapshot) - interval '180 days'
             THEN 1 ELSE 0 END AS is_churned
    FROM orders AS o
    INNER JOIN customers AS c   ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
tiered AS (
    SELECT
        customer_unique_id,
        is_churned,
        NTILE(4) OVER (ORDER BY total_spend) AS spend_tier
    FROM customer_status
)
SELECT
    spend_tier,
    count(*) AS total_customers,
    sum(is_churned) AS churned,
    round(100.0 * sum(is_churned) / count(*), 2) AS churn_rate
FROM tiered
GROUP BY spend_tier
ORDER BY spend_tier;

--Q6
WITH snapshot AS (
    SELECT max(order_purchase_timestamp) AS snap_date FROM orders
),
customer_status AS (
    SELECT
        c.customer_unique_id,
        sum(oi.price + oi.freight_value) AS total_spend,
        CASE WHEN max(o.order_purchase_timestamp)
                  < (SELECT snap_date FROM snapshot) - interval '180 days'
             THEN 1 ELSE 0 END AS is_churned
    FROM orders AS o
    INNER JOIN customers AS c   ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_spend DESC) AS rank,
    customer_unique_id,
    total_spend
FROM customer_status
ORDER BY total_spend DESC
LIMIT 20;

--Q7
WITH monthly AS (
    SELECT
        date_trunc('month', order_purchase_timestamp) AS order_month,
        sum(oi.price + oi.freight_value) AS total_revenue
    FROM orders AS o
    INNER JOIN order_items AS oi
    ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY date_trunc('month', o.order_purchase_timestamp)
)
SELECT
 order_month,
 total_revenue,
 LAG(total_revenue) OVER (ORDER BY order_month) AS previous_month_revenue,
 (total_revenue - LAG(total_revenue) OVER (ORDER BY order_month)) AS MoM_change
FROM monthly
ORDER BY order_month;

--Q8
WITH monthly AS (
    SELECT
        date_trunc('month', order_purchase_timestamp) AS order_month,
        sum(oi.price + oi.freight_value) AS total_revenue
    FROM orders AS o
    INNER JOIN order_items AS oi
    ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY date_trunc('month', o.order_purchase_timestamp)
)
SELECT
    order_month,
    total_revenue,
    sum(total_revenue) OVER (ORDER BY order_month) AS cumulative_revenue
FROM monthly
ORDER BY order_month;

--Q9
SELECT
    c.customer_unique_id,
    o.order_id,
    o.order_purchase_timestamp,
    ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id
                       ORDER BY o.order_purchase_timestamp) AS order_seq
FROM orders AS o
INNER JOIN customers AS c 
ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
ORDER BY  order_seq DESC
LIMIT 20;

--Q10
WITH customer_frequency AS (
    SELECT
        c.customer_unique_id,
        count(*) AS order_count
    FROM orders AS o
    INNER JOIN customers AS c
    ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
segmented AS (
    SELECT
        customer_unique_id,
        order_count,
        NTILE(5) OVER (ORDER BY order_count) AS frequency_segment
    FROM customer_frequency
)
SELECT
    frequency_segment,
    count(*) AS customers,
    min(order_count) AS min_orders,
    max(order_count) AS max_orders,
    round(avg(order_count), 2) AS avg_orders
FROM segmented
GROUP BY frequency_segment
ORDER BY frequency_segment;
