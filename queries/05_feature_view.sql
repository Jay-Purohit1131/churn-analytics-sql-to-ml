CREATE OR REPLACE VIEW feature_view AS (
WITH snapshot AS (
    SELECT
        max(order_purchase_timestamp) AS snap_date
    FROM orders
),
order_features AS (
    SELECT
        c.customer_unique_id,
        count(DISTINCT o.order_id) AS order_count,
        sum(oi.price + oi.freight_value) AS total_spend,
        sum(oi.price + oi.freight_value) / count(DISTINCT o.order_id) AS avg_spend,
        EXTRACT(DAY FROM (max(o.order_purchase_timestamp) - min(o.order_purchase_timestamp))) AS tenure,
        EXTRACT(DAY FROM ((SELECT snap_date FROM snapshot) - max(o.order_purchase_timestamp))) AS recency,
        CASE WHEN max(o.order_purchase_timestamp)
                  < (SELECT snap_date FROM snapshot) - interval '180 days'
             THEN 1 ELSE 0 END AS is_churned
    FROM orders AS o
    INNER JOIN customers AS c    ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
review_features AS (
    SELECT
        c.customer_unique_id,
        avg(r.review_score) AS avg_review_score
        -- optionally: count(r.review_id) AS review_count
    FROM order_reviews AS r
    INNER JOIN orders AS o    ON o.order_id = r.order_id
    INNER JOIN customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    of.customer_unique_id,
    of.order_count,
    of.total_spend,
    of.avg_spend,
    of.tenure,
    of.recency,
    rf.avg_review_score,
    of.is_churned
FROM order_features AS of
LEFT JOIN review_features AS rf
    USING (customer_unique_id)
);