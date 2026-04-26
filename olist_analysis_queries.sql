CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

CREATE TABLE payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

CREATE TABLE reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(100),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g DECIMAL(10,2),
    product_length_cm DECIMAL(10,2),
    product_height_cm DECIMAL(10,2),
    product_width_cm DECIMAL(10,2)
);

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

CREATE TABLE category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

COPY payments 
FROM 'C:\Users\akash\OneDrive\Desktop\Olist_Projects\Data\olist_order_payments_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY customers 
FROM 'C:\Users\akash\OneDrive\Desktop\Olist_Projects\Data\olist_customers_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY products 
FROM 'C:\Users\akash\OneDrive\Desktop\Olist_Projects\Data\olist_products_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY sellers 
FROM 'C:\Users\akash\OneDrive\Desktop\Olist_Projects\Data\olist_sellers_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY orders 
FROM 'C:\Users\akash\OneDrive\Desktop\Olist_Projects\Data\olist_orders_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY order_items 
FROM 'C:\Users\akash\OneDrive\Desktop\Olist_Projects\Data\olist_order_items_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY payments 
FROM 'C:\Users\akash\OneDrive\Desktop\Olist_Projects\Data\olist_order_payments_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY reviews 
FROM 'C:\Users\akash\OneDrive\Desktop\Olist_Projects\Data\olist_order_reviews_dataset.csv'
DELIMITER ',' CSV HEADER;

COPY category_translation 
FROM 'C:\Users\akash\OneDrive\Desktop\Olist_Projects\Data\product_category_name_translation.csv'
DELIMITER ',' CSV HEADER;


SELECT 'customers' as table_name, COUNT(*) as row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL


TRUNCATE TABLE payments;
COPY payments 
FROM 'C:\Users\akash\OneDrive\Desktop\Olist_Projects\Data\olist_order_payments_dataset.csv'
DELIMITER ',' CSV HEADER;
SELECT 'category_translation', COUNT(*) FROM category_translation;
SELECT COUNT(*) FROM payments;
SELECT COUNT(*) FROM category_translation;









-- Business Overview
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_revenue,
    ROUND(AVG(p.payment_value)::numeric, 2) AS avg_order_value,
    COUNT(DISTINCT oi.seller_id) AS total_sellers
FROM orders o
JOIN payments p ON o.order_id = p.order_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';


-- On-Time vs Late Deliveries
SELECT
    COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date 
          THEN 1 END) AS on_time_orders,
    COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date 
          THEN 1 END) AS late_orders,
    ROUND(COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date 
          THEN 1 END) * 100.0 / COUNT(*), 2) AS on_time_rate
FROM orders
WHERE order_status = 'delivered';

-- Monthly Revenue Trend
SELECT 
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value)::numeric, 2) AS monthly_revenue
FROM orders o
JOIN payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM')
ORDER BY month;

-- Top 10 Product Categories by Revenue
SELECT 
    ct.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price)::numeric, 2) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY ct.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;


-- Impact of Late Delivery on Review Scores
SELECT
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date 
        THEN 'On-Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_review_score
FROM orders o
JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY delivery_status
ORDER BY avg_review_score DESC;


-- Top 10 Sellers by Revenue
SELECT 
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price)::numeric, 2) AS total_revenue,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_review_score
FROM order_items oi
JOIN reviews r ON oi.order_id = r.order_id
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 10;


-- Payment Method Breakdown
SELECT 
    payment_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(payment_value)::numeric, 2) AS total_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM payments
GROUP BY payment_type
ORDER BY total_transactions DESC;


-- Average Delivery Delay by Month
SELECT 
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS month,
    COUNT(*) AS total_orders,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - 
          order_estimated_delivery_date))/86400)::numeric, 1) AS avg_delay_days,
    COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date 
          THEN 1 END) AS late_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY TO_CHAR(order_purchase_timestamp, 'YYYY-MM')
ORDER BY month;