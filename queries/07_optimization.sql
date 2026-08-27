EXPLAIN ANALYZE
SELECT customer_id, count(*)
FROM orders
WHERE order_status = 'delivered'
GROUP BY customer_id;

CREATE INDEX idx_orders_status ON orders (order_status);

EXPLAIN ANALYZE
SELECT customer_id, count(*)
FROM orders
WHERE order_status = 'delivered'
GROUP BY customer_id;
