SELECT 
    count(order_id) AS total_orders,
    min(order_purchase_timestamp) AS earliest_order,
    max(order_purchase_timestamp) AS latest_order
FROM orders;


SELECT
    count(*)                                        AS total_rows,
    count(*) - count(order_approved_at)             AS null_approved_at,
    count(*) - count(order_delivered_carrier_date)  AS null_delivered_carrier,
    count(*) - count(order_delivered_customer_date) AS null_delivered_customer,
    count(*) - count(order_purchase_timestamp)      AS null_purchase_ts
FROM orders;


WITH totals AS (
    SELECT count(DISTINCT c.customer_unique_id) AS total_customers
    FROM orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
repeaters AS (
    SELECT count(*) AS repeating_customers
    FROM (
        SELECT c.customer_unique_id
        FROM orders AS o
        INNER JOIN customers AS c
            ON o.customer_id = c.customer_id
        WHERE o.order_status = 'delivered'
        GROUP BY c.customer_unique_id
        HAVING count(*) > 1
    ) AS r
)
SELECT
    totals.total_customers,
    repeaters.repeating_customers,
    round(100.0 * repeaters.repeating_customers / totals.total_customers, 2) AS repeat_pct
FROM totals, repeaters;

SELECT 
    count(*) AS total_orders,
    order_status
FROM orders
GROUP BY order_status