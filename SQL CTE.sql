USE BikeStores;
--BT1
SELECT 
	month,
	brand_name,
	net_sales,
	LAG(net_sales,1) OVER (
		PARTITION BY brand_name
		ORDER BY month
	) AS previous_sales,
	round(Cast(100*(net_sales - LAG(net_sales) OVER (PARTITION BY brand_name ORDER BY month ))
	/ (LAG(net_sales) OVER (PARTITION BY brand_name ORDER BY month )) AS FLOAT), 2)
	AS vs_previous_sales
FROM 
	sales.vw_netsales_brands
WHERE
	year = 2018;


--BT2
WITH cte_netsales_2018 AS(
	SELECT 
		month, 
		SUM(net_sales) net_sales
	FROM 
		sales.vw_netsales_brands
	WHERE 
		year = 2018
	GROUP BY 
		month
)
SELECT 
	month,
	brand_name,
	net_sales,
	LEAD(net_sales,1) OVER (
		PARTITION BY brand_name
		ORDER BY month
	) AS next_month_sales
FROM 
	sales.vw_netsales_brands
WHERE
	year = 2018;

--BT3
WITH cte_netsales AS(
SELECT 
	CONCAT_WS(' ',first_name,last_name) full_name,
    net_sales, 
    year,
    CUME_DIST() OVER (
        PARTITION BY year
        ORDER BY net_sales DESC
    ) cume_dist
FROM 
    sales.vw_staff_sales t
INNER JOIN sales.staffs m on m.staff_id = t.staff_id
WHERE 
    year IN (2016,2017)
)
SELECT * 
FROM cte_netsales
WHERE cume_dist <= 0.2

--BT4
WITH cte_netsales AS(
SELECT 
	year,
	CONCAT_WS(' ',first_name,last_name) full_name,
    net_sales, 
	CONVERT(nvarchar, PERCENT_RANK() OVER (PARTITION BY year ORDER BY net_sales DESC) *100) + '%' AS PctRank  
FROM 
    sales.vw_staff_sales t
INNER JOIN sales.staffs m on m.staff_id = t.staff_id
WHERE 
    year IN (2016,2017)
	)
SELECT * 
FROM cte_netsales

--dùng hàm Format
