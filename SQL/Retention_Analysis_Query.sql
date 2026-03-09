WITH first_purchase AS (
  SELECT
    Customer_ID,
    DATE_TRUNC(MIN(order_date), MONTH) AS cohort_month,
    EXTRACT(YEAR FROM MIN(order_date)) AS cohort_year
  FROM `Retail_Sales.clean_transactions`
  GROUP BY Customer_ID
),

user_activity AS (
  SELECT
    t.Customer_ID,
    f.cohort_month,
    f.cohort_year,
    DATE_TRUNC(t.order_date, MONTH) AS activity_month,
    DATE_DIFF(DATE_TRUNC(t.order_date, MONTH), f.cohort_month, MONTH) AS month_number
  FROM `Retail_Sales.clean_transactions` t
  JOIN first_purchase f
    ON t.Customer_ID = f.Customer_ID
),

cohort_activity AS (
  SELECT
    cohort_month,
    cohort_year,
    month_number,
    COUNT(DISTINCT Customer_ID) AS active_users
  FROM user_activity
  WHERE month_number >= 0
  GROUP BY cohort_month, cohort_year, month_number
),

cohort_size AS (
  SELECT
    cohort_month,
    cohort_year,
    COUNT(DISTINCT Customer_ID) AS cohort_users
  FROM first_purchase
  GROUP BY cohort_month, cohort_year
)

SELECT
  ca.cohort_month,
  ca.cohort_year,
  ca.month_number,
  cs.cohort_users,
  ca.active_users,
  ROUND(SAFE_DIVIDE(ca.active_users, cs.cohort_users) , 2) AS retention_rate
FROM cohort_activity ca
JOIN cohort_size cs
  ON ca.cohort_month = cs.cohort_month
  AND ca.cohort_year = cs.cohort_year
ORDER BY cohort_year, cohort_month, month_number;