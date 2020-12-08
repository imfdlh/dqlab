--JUMLAH TRANSAKSI PER BULAN--

SELECT
	DATE_FORMAT(created_at, '%Y-%m') AS Bulan,
	count(1) AS jumlah_transaksi
FROM
	orders
GROUP BY
	1
ORDER BY
	1;
	
--STATUS TRANSAKSI--

--transaksi tidak dibayar
SELECT count(1) AS jumlah_transaksi FROM orders WHERE paid_at = 'NA';

--transaksi sudah dibayar tapi tidak dikirim
SELECT count(1) AS jumlah_transaksi FROM orders WHERE paid_at != 'NA' AND delivery_at = 'NA';

--transaksi tidak dikirim, baik yang sudah dibayar maupun belum
SELECT count(1) AS jumlah_transaksi FROM orders WHERE delivery_at = 'NA' AND (paid_at != 'NA' OR paid_at = 'NA');

--transaksi dikirim pada hari yang sama dengan tanggal dibayar
SELECT count(1) AS jumlah_transaksi FROM orders WHERE paid_at = delivery_at;

--PENGGUNA BERTRANSAKSI--

--total seluruh pengguna
SELECT count(DISTINCT user_id) FROM users;

--total pengguna yang pernah bertransaksi sebagai pembeli
SELECT count(DISTINCT buyer_id) FROM orders;

--total pengguna yang pernah bertransaksi sebagai penjual
SELECT count(DISTINCT seller_id) FROM orders;

--total penggua yang pernah bertransaksi sebagai pembeli dan pernah sebagai penjual
SELECT count(DISTINCT seller_id) FROM orders WHERE seller_id IN (SELECT buyer_id FROM orders);

--total pengguna yang tidak pernah bertransaksi sebagai pembeli maupun penjual
SELECT count(DISTINCT user_id) FROM users
WHERE
	user_id
	NOT IN
	(
		SELECT buyer_id FROM orders UNION SELECT seller_id FROM orders
	);
--(ATAU)
SELECT count(DISTINCT user_id) FROM users
WHERE
	user_id
	NOT IN
	(
		SELECT buyer_id FROM orders
	)
	AND
	user_id
	NOT IN
	(
		SELECT seller_id FROM orders
	);

--TOP BUYER ALL TIME--

SELECT
	buyer_id,
	nama_user,
	sum(total) AS total_transaksi
FROM
	orders o
JOIN
	users u
	ON o.buyer_id = u.user_id
GROUP BY
	1,2
ORDER BY
	3 DESC
LIMIT
	5;

--FREQUENT BUYER--

SELECT
	buyer_id,
	nama_user,
	count(order_id) AS jumlah_transaksi
FROM
	orders o
JOIN
	users u
	ON o.buyer_id = u.user_id
WHERE 
	discount = 0
GROUP BY
	1,2
ORDER BY
	3 DESC, 2
LIMIT
	5;

--BIG FREQUENT BUYER 2020--

SELECT
	buyer_id,
	email,
	rata_rata,
	month_count
FROM
(
	SELECT
		trx.buyer_id,
		rata_rata,
		jumlah_order,
		month_count
	FROM
	(
		SELECT
			buyer_id,
			round(avg(total),2) AS rata_rata
		FROM
			orders
		WHERE     
			DATE_FORMAT(created_at, '%Y') = '2020'
		GROUP BY
			1
		HAVING
			rata_rata > 1000000
		ORDER BY
			1
	) AS trx
	JOIN
		(
			SELECT
				buyer_id,
				count(order_id) AS jumlah_order,
				count(DISTINCT DATE_FORMAT(created_at, '%m')) AS month_count
			FROM
				orders
			WHERE     
				DATE_FORMAT(created_at, '%Y') = '2020'
			GROUP BY
				1
			HAVING
				month_count >= 5
				AND
				jumlah_order >= month_count
			ORDER BY
				1
		) AS months
		ON trx.buyer_id = months.buyer_id
) AS bfq
JOIN
	users
	ON buyer_id = user_id;

--DOMAIN EMAIL DARI PENJUAL--

SELECT
	DISTINCT substr(email, instr(email, '@') + 1) AS domain_email,
	count(user_id) AS jumlah_pengguna_seller
FROM
	users
WHERE
	user_id IN
	(
		SELECT seller_id FROM orders
	)
GROUP BY
	 1;
 
--TOP 5 PRODUCT DESEMBER 2019--

SELECT
	sum(quantity) AS total_quantity,
	desc_product
FROM
	order_details od
JOIN
	products p
	ON od.product_id = p.product_id
JOIN
	orders o
	ON od.order_id = o.order_id
WHERE
	created_at BETWEEN '2019-12-01' AND '2019-12-31'
GROUP BY
	2
ORDER BY
	1 DESC
LIMIT
	5;

--TRANSAKSI PER BULAN DI TAHUN 2020--

SELECT
	EXTRACT(YEAR_MONTH FROM created_at) AS tahun_bulan,
	count(1) AS jumlah_transaksi,
	sum(total) AS total_nilai_transaksi
FROM
	orders
WHERE
	created_at >= '2020-01-01'
GROUP BY
	1
ORDER BY
	1;

--PENGGUNA DENGAN RATA — RATA TRANSAKSI TERBESAR DI JANUARI 2020--

SELECT
	buyer_id,
	count(1) AS jumlah_transaksi,
	avg(total) AS avg_nilai_transaksi
FROM
	orders
WHERE
	created_at >= '2020-01-01' AND created_at < '2020-02-01'
GROUP BY
	1
HAVING
	count(1) >=  2 
ORDER BY
	3 DESC
LIMIT
	10;

--TRANSAKSI BESAR DI DESEMBER 2019--

SELECT
	nama_user AS nama_pembeli,
	total AS nilai_transaksi,
	created_at AS tanggal_transaksi
FROM
	orders
INNER JOIN
	users
	ON buyer_id = user_id
WHERE
	created_at >= '2019-12-01' AND created_at < '2020-01-01' AND total >= 20000000
ORDER BY
	1;

--KATEGORI PRODUK TERLARIS DI 2020--

SELECT
	category,
	sum(quantity) AS total_quantity,
	sum(price) AS total_price
FROM
	orders
INNER JOIN
	order_details
	USING(order_id)
INNER JOIN
	products
	USING(product_id)
WHERE
	created_at >= '2020-01-01' AND delivery_at IS NOT NULL
GROUP BY
	1
ORDER BY
	2 DESC
LIMIT
	5;

--MENCARI PEMBELI HIGH VALUE--

SELECT
	nama_user AS nama_pembeli,
	count(1) AS jumlah_transaksi,
	sum(total) AS total_nilai_transaksi,
	min(total) AS min_nilai_transaksi
FROM
	orders
INNER JOIN
	users
	ON buyer_id = user_id
GROUP BY
	user_id,
	nama_user
HAVING
	count(1) > 5 AND min(total) > 2000000
ORDER BY
	3 DESC;

--MENCARI DROPSHIPPER--

SELECT
	nama_user AS nama_pembeli,
	count(1) AS jumlah_transaksi,
	count(DISTINCT orders.kodepos) AS distinct_kodepos,
	sum(total) AS total_nilai_transaksi,
	avg(total) AS avg_nilai_transaksi
FROM
	orders 
INNER JOIN
	users
	ON buyer_id = user_id
GROUP BY
	user_id,
	nama_user
HAVING
	count(1) >= 10 AND count(1) = count(DISTINCT orders.kodepos)
ORDER BY
	2 DESC;

--MENCARI RESELLER OFFLINE--

SELECT
	nama_user AS nama_pembeli,
	count(1) AS jumlah_transaksi,
	sum(total) AS total_nilai_transaksi,
	avg(total) AS avg_nilai_transaksi,
	avg(total_quantity) AS avg_quantity_per_transaksi
FROM
	orders
INNER JOIN
	users
	ON buyer_id = user_id
INNER JOIN
	(
		SELECT order_id, sum(quantity) AS total_quantity
		FROM order_details
		GROUP BY 1
	) AS summary_order
	USING(order_id)
WHERE
	orders.kodepos = users.kodepos
GROUP BY
	user_id,
	nama_user
HAVING
	count(1) >= 8 AND avg(total_quantity) > 10
ORDER BY
	3 DESC;

--PEMBELI SEKALIGUS PENJUAL--

SELECT
	nama_user AS nama_pengguna,
	jumlah_transaksi_beli,
	jumlah_transaksi_jual
FROM
	users
INNER JOIN
	(
		SELECT buyer_id, count(1) AS jumlah_transaksi_beli
		FROM orders
		GROUP BY 1
	) AS buyer
	ON buyer_id = user_id
INNER JOIN
	(
		SELECT seller_id, count(1) AS jumlah_transaksi_jual
		FROM orders
		GROUP BY 1
	) AS seller
	ON seller_id = user_id
WHERE
	jumlah_transaksi_beli >= 7
ORDER BY
	1;

--LAMA TRANSAKSI DIBAYAR--

SELECT
	EXTRACT(YEAR_MONTH FROM created_at) AS tahun_bulan,
	count(1) AS jumlah_transaksi,
	avg(datediff(paid_at, created_at)) AS avg_lama_dibayar,
	min(datediff(paid_at, created_at)) AS min_lama_dibayar,
	max(datediff(paid_at, created_at)) AS max_lama_dibayar
FROM
	orders
WHERE
	paid_at IS NOT NULL
GROUP BY
	1
ORDER BY
	1;
