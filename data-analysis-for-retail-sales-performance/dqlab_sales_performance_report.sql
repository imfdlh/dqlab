--(1A)--

SELECT
	DISTINCT strftime('%Y', order_date) AS years,
	sum(sales) AS sales,
	count(order_id) AS number_of_order
FROM
	dqlab_sales_store
WHERE
	order_status = 'Order Finished'
GROUP BY
	1
ORDER BY
	1;
	
--(1B)--

SELECT
	strftime('%Y', order_date) AS years,
	product_sub_category,
	sum(sales) AS sales
FROM
	dqlab_sales_store
WHERE
	(strftime('%Y', order_date) BETWEEN '2011' AND '2012')
	AND
	order_status = 'Order Finished'
GROUP BY
	1,2
ORDER BY
	1,3 DESC;
	
--(2A)--

SELECT
	strftime('%Y', order_date) AS years,
	sum(sales) AS sales,
	sum(discount_value) AS promotion_value,
	round((round(sum(discount_value),2) / round(sum(sales),2))*100,2) AS burn_rate_percentage
FROM
	dqlab_sales_store
WHERE
	order_status = 'Order Finished'
GROUP BY
	1
ORDER BY
	1;

--(2B)--

SELECT
	strftime('%Y', order_date) AS years,
	product_sub_category,
	product_category,
	sum(sales) AS sales,
	sum(discount_value) AS promotion_value,
	round((round(sum(discount_value),2) / round(sum(sales),2))*100,2) AS burn_rate_percentage
FROM
	dqlab_sales_store
WHERE
	order_status = 'Order Finished'
	AND
	strftime('%Y', order_date) = '2012'
GROUP BY
	3,2,1
ORDER BY
	4 DESC;

--(3A)--

SELECT
	strftime('%Y', order_date) AS years,
	count(DISTINCT lower(customer)) AS number_of_customer
FROM
	dqlab_sales_store
WHERE
	order_status = 'Order Finished'
GROUP BY
	1
ORDER BY
	1;

--(3B)--

SELECT
	strftime('%Y', first_trx_date) AS years,
	count(customer) AS number_of_new_customer
FROM
(
	SELECT
		DISTINCT lower(customer) AS customer,
		min(order_date) AS first_trx_date
	FROM
		dqlab_sales_store
	WHERE
		order_status = 'Order Finished'
	GROUP BY
		1
) AS first_trx
GROUP BY
	1
ORDER BY
	1;

--(3C)--

WITH trx_2009 AS (
	SELECT
		*
	FROM
		dqlab_sales_store
	WHERE
		strftime('%Y', order_date) = '2009'
		AND
		order_status = 'Order Finished'
)
,
cohort_items AS (
  	SELECT
		DISTINCT customer,
  		strftime('%m', min(order_date)) AS cohort_month
  	FROM
  		trx_2009
	GROUP BY
		1
  	ORDER BY
  		1,2
),

user_activities AS (
	SELECT
		T.customer,
		(strftime('%m', order_date) - cohort_month) AS month_number
	FROM
		trx_2009 T
	LEFT JOIN
		cohort_items C
		ON
		T.customer = C.customer
	GROUP BY
		1,2
),
cohort_size AS (
	SELECT
		cohort_month,
		count(1) AS num_users
	FROM
		cohort_items
	GROUP BY
		1
	ORDER BY
		1
),
retention_table AS (
	SELECT
		C.cohort_month,
		A.month_number,
		count(1) AS num_users
	FROM
		user_activities A
	LEFT JOIN
		cohort_items C
		ON
		A.customer = C.customer
	GROUP BY
		1,2
)

SELECT
	B.cohort_month,
	S.num_users AS total_users,
	B.month_number,
	round(round(B.num_users,2) * 100 / round(S.num_users,2),2) AS percentage
FROM
	retention_table B
LEFT JOIN
	cohort_size S
	ON
	B.cohort_month = S.cohort_month
WHERE
	B.cohort_month IS NOT NULL
ORDER BY
	1,3;
