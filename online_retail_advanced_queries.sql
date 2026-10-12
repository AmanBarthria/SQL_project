
-- =====================================================
-- ONLINE RETAIL BUSINESS ANALYSIS
-- SQL Dialect: PostgreSQL
-- =====================================================


-- QUERY 1: TOP 3 REVENUE-GENERATING PRODUCTS
-- Original practice query supplied by Aman
-- Skills: CTE, JOIN, GROUP BY, DENSE_RANK

WITH t1 AS (
    SELECT
        c.category_name,
        p.product_name,
        SUM(oi.line_total) AS revenue
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        c.category_name,
        p.product_name
),
t2 AS (
    SELECT
        category_name,
        product_name,
        revenue,
        DENSE_RANK() OVER (
            PARTITION BY category_name
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM t1
)
SELECT
    category_name,
    product_name,
    revenue,
    revenue_rank
FROM t2
WHERE revenue_rank <= 3
ORDER BY category_name, revenue_rank;


-- =====================================================
-- QUERY 2: MONTHLY REVENUE AND MONTH-OVER-MONTH CHANGE
-- Skills: CTE, DATE_TRUNC, LAG, Window Functions
-- =====================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::date AS sales_month,
        SUM(oi.line_total) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)::date
),
revenue_comparison AS (
    SELECT
        sales_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    sales_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS mom_growth_pct
FROM revenue_comparison
ORDER BY sales_month;


-- =====================================================
-- QUERY 3: TOP CUSTOMERS BY TOTAL ORDER VALUE
-- Skills: JOIN, GROUP BY, HAVING, DENSE_RANK
-- =====================================================

WITH customer_sales AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.city,
        COUNT(o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_order_value,
        AVG(o.total_amount) AS average_order_value
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.city
)
SELECT
    customer_id,
    first_name,
    last_name,
    city,
    total_orders,
    ROUND(total_order_value, 2) AS total_order_value,
    ROUND(average_order_value, 2) AS average_order_value,
    DENSE_RANK() OVER (
        ORDER BY total_order_value DESC
    ) AS customer_rank
FROM customer_sales
ORDER BY customer_rank
LIMIT 10;


-- =====================================================
-- QUERY 4: CATEGORY-WISE REVENUE CONTRIBUTION
-- Skills: CTE, JOIN, GROUP BY, Window Aggregation
-- =====================================================

WITH category_sales AS (
    SELECT
        c.category_name,
        SUM(oi.line_total) AS category_revenue
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY c.category_name
)
SELECT
    category_name,
    ROUND(category_revenue, 2) AS category_revenue,
    ROUND(
        100.0 * category_revenue
        / NULLIF(SUM(category_revenue) OVER (), 0),
        2
    ) AS revenue_contribution_pct,
    DENSE_RANK() OVER (
        ORDER BY category_revenue DESC
    ) AS category_rank
FROM category_sales
ORDER BY category_rank;
