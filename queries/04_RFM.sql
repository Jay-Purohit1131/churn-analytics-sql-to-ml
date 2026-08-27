WITH snapshot AS (
    SELECT max(order_purchase_timestamp) AS snap_date FROM orders
),
rfm_base AS (
    SELECT
        c.customer_unique_id,
        (SELECT snap_date FROM snapshot) - max(o.order_purchase_timestamp) AS recency,
        count (DISTINCT o.order_id) AS frequency,
        sum(oi.price + oi.freight_value) AS monetary
    FROM orders AS o
    INNER JOIN customers AS c    
    ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi 
    ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scored AS(
    SELECT 
        customer_unique_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,   
        NTILE(5) OVER (ORDER BY frequency)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary)     AS m_score
    FROM rfm_base
)
SELECT
    customer_unique_id,
    recency, 
    frequency, 
    monetary,
    r_score, 
    f_score, 
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 THEN 'champions'
        WHEN r_score >= 4                  THEN 'recent'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'at-risk'
        WHEN r_score <= 2                  THEN 'lost'
        ELSE 'regular'
    END AS segment
FROM rfm_scored
ORDER BY r_score DESC, f_score DESC;
