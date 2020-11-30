SELECT * FROM orders_1 LIMIT 5;
SELECT * FROM orders_2 LIMIT 5;
SELECT * FROM customer LIMIT 5;

--(1A)--

SELECT
	sum(quantity) AS total_penjualan,
	sum(quantity*priceeach) AS revenue
FROM
	orders_1
WHERE
	status = 'Shipped';

SELECT
	sum(quantity) AS total_penjualan,
	sum(quantity*priceeach) AS revenue
FROM
	orders_2
WHERE
	status = 'Shipped';

--(1B)--

SELECT
	quarter,
	sum(quantity) AS total_penjualan,
	sum(quantity * priceeach) AS revenue,
	CAST(round((sum(quantity) - lag(sum(quantity)) OVER(ORDER BY quarter)) * 100 / round(lag(sum(quantity)) OVER(ORDER BY quarter),2),2) AS TEXT) || '%'  AS growth_penjualan,
	CAST(round((sum(quantity * priceeach) - lag(sum(quantity * priceeach)) OVER(ORDER BY quarter)) * 100 / round(lag(sum(quantity * priceeach)) OVER(ORDER BY quarter),2),2) AS TEXT) || '%'  AS growth_revenue
FROM
(
	SELECT
		orderNumber,
		status,
		quantity,
		priceEach,
		'1' AS quarter
	FROM
		orders_1
	UNION
	SELECT
		orderNumber,
		status,
		quantity,
		priceEach,
		'2' AS quarter
	FROM
		orders_2
	) AS tabel_a
WHERE
	status = 'Shipped'
GROUP BY
	1;

--(2)--

SELECT
	quarter,
	count(DISTINCT customerID) AS total_customers
FROM
(
	SELECT
		customerID,
		createDate,
		CASE
			WHEN CAST(strftime('%m', createDate) AS INTEGER) BETWEEN 1 AND 3 THEN 1
			ELSE 2
		END as quarter
	FROM
		customer
	WHERE
		createDate BETWEEN '2004-01-01' AND '2004-06-30'
) AS tabel_b
GROUP BY
	1;

--(3)--

SELECT
	quarter,
	count(DISTINCT customerID) AS total_customers
FROM
(
	SELECT
		customerID,
		createDate,
		CASE
			WHEN CAST(strftime('%m', createDate) AS INTEGER) BETWEEN 1 AND 3 THEN 1
			ELSE 2
		END AS quarter
	FROM
		customer
	WHERE
		(createDate BETWEEN '2004-01-01' AND '2004-06-30')
		AND
		customerID IN
		(
			SELECT
				DISTINCT customerID
			FROM
				orders_1
			UNION
			SELECT
				DISTINCT customerID
			FROM
				orders_2
		)
) AS tabel_b
GROUP BY
	1;

--(4)--

SELECT * FROM
(
	SELECT
		substr(productCode, 1, 3) AS categoryID,
		count(DISTINCT orderNumber) AS total_order,
		sum(quantity) AS total_penjualan
	FROM
	(
		SELECT
			productCode,
			orderNumber,
			quantity,
			status
		FROM
			orders_2
		WHERE
			status = 'Shipped'
	) AS tabel_c
  	GROUP BY
	1
) AS c
ORDER BY
	2 DESC;

--(5)--

--Menghitung total unik customers yang transaksi di quarter_1
SELECT count(DISTINCT customerID) AS total_customers FROM orders_1;
--output = 25

SELECT
	'1' AS quarter,
	CAST(round(count(DISTINCT customerID) * 100 / round(25,2),2) AS TEXT) || '%' AS q2
FROM
	orders_1
WHERE
	customerID IN
	(
	  	SELECT
	  		DISTINCT customerID
	  	FROM
	  		orders_2
	);