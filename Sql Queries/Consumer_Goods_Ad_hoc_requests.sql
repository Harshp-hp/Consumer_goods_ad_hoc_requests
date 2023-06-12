USE gdb023;

-- Qus. 1
-- Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

SELECT 
    *
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';

-- Qus. 2        
-- What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg
   
WITH 
	Unique_products_2020 AS (
    SELECT 
		COUNT(DISTINCT product_code) as count
    FROM 
		fact_sales_monthly
    WHERE 
		fiscal_year = 2020
        ),
     Unique_products_2021 AS (
     SELECT 
		COUNT(DISTINCT product_code) as count
     FROM 
		fact_sales_monthly
     WHERE 
		fiscal_year = 2021
        ),
     Percentage_change AS (
     SELECT 
		(((Unique_products_2021.count - Unique_products_2020.count) / Unique_products_2020.count) * 100)  AS Percentage_Chng
     FROM 
		Unique_products_2020,
        Unique_products_2021
     )
   SELECT
		Unique_products_2020.count AS unique_product_2020,
        Unique_products_2021.count AS unique_product_2021,
        Percentage_change.Percentage_Chng
   FROM 
		Unique_products_2020,
        Unique_products_2021,
        Percentage_change;
        
-- Qus. 3        
-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count 

SELECT 
    segment, COUNT(DISTINCT product_code) AS product_code
FROM
    dim_product
GROUP BY segment
ORDER BY product_code DESC;       

-- Qus. 4 
-- Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

WITH 
	f_2020 AS (
		SELECT segment,product_code
        FROM dim_product
        JOIN fact_sales_monthly USING(product_code)
        WHERE fiscal_year = 2020
        ),
     f_2021 AS (
		SELECT segment, product_code
        FROM dim_product
        JOIN fact_sales_monthly USING(product_code)
        WHERE fiscal_year = 2021
        ),
     f_2020_agg AS (
		SELECT segment, COUNT(DISTINCT product_code) as product_code_2020
        FROM f_2020
        GROUP BY segment
        ),
    f_2021_agg AS (
		SELECT segment, COUNT(DISTINCT product_code) as product_code_2021
        FROM f_2021
        GROUP BY segment
        )
      SELECT 
			f_2020_agg.segment,
            f_2020_agg.product_code_2020,
            f_2021_agg.product_code_2021,
            (f_2021_agg.product_code_2021 - f_2020_agg.product_code_2020) as difference 
       FROM 
			f_2020_agg
       JOIN 	
			f_2021_agg USING(segment)
       ORDER BY difference DESC;    
       
-- Que. 5	
-- Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost   

SELECT 	
	product_code,product,manufacturing_cost
FROM dim_product
JOIN fact_manufacturing_cost USING(product_code)
WHERE manufacturing_cost IN (
		SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
        UNION 
        SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost
    );
    
 
	-- Qus. 6 
	-- Generate a report which contains the top 5 customers who received an
	-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
	-- Indian market. The final output contains these fields,
	-- customer_code
	-- customer
	-- average_discount_percentage 

	SELECT 
		dim_customer.customer_code,
		customer,
		round(((pre_invoice_discount_pct)*100),2) AS average_discount_percentage
	FROM 
			fact_pre_invoice_deductions
			JOIN dim_customer ON fact_pre_invoice_deductions.customer_code = dim_customer.customer_code
	WHERE 
				fiscal_year = 2021 AND market  = 'India'
	GROUP BY customer_code, customer
	ORDER BY average_discount_percentage DESC
	LIMIT 5;    

-- Qus. 7 
-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount        

SELECT 
	EXTRACT(month FROM fact_sales_monthly.date) AS Month,
    EXTRACT(year FROM fact_sales_monthly.date) AS Year,
    ROUND(SUM((gross_price * sold_quantity)), 2) AS gross_sales_amount
FROM 
		fact_sales_monthly
JOIN 	dim_customer USING(customer_code)
JOIN 	fact_gross_price USING(product_code)
WHERE 
		dim_customer.customer = "Atliq Exclusive"
GROUP BY Month, Year
ORDER BY 
	Year ASC,
	Month ASC;   
    
-- Qus. 8 
-- In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity
   
   
WITH
	Quarters AS (
    SELECT *,
    CASE
		WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
        WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
        WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
        WHEN MONTH(date) IN (6,7,8) THEN 'Q4'
    END AS Quarter
FROM fact_sales_monthly
WHERE fiscal_year = 2020 
)

SELECT Quarter, SUM(sold_quantity) AS total_sold_quantity
FROM Quarters
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;
   
-- Qus. 9 
-- Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage   

WITH channel_gross AS 
(
	SELECT 	
		dim_customer.channel,
        ROUND(SUM(gross_price * sold_quantity), 2) AS gross_sales_mln
    From fact_sales_monthly
    JOIN dim_customer on fact_sales_monthly.customer_code = dim_customer.customer_code
    JOIN fact_gross_price on fact_sales_monthly.product_code = fact_gross_price.product_code
    WHERE fact_sales_monthly.fiscal_year = 2021
    GROUP BY dim_customer.channel
    ORDER BY gross_sales_mln DESC
)
SELECT 
	channel,
    gross_sales_mln,
    ROUND((gross_sales_mln * 100 / SUM(gross_sales_mln) over()), 3) AS Percentage
FROM  channel_gross;   

-- Qus 10:
-- Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order


WITH 
	division_sales AS (
		SELECT 
			dp.division,
            fsm.product_code,
            dp.product,
            SUM(fsm.sold_quantity) AS total_sold_quantity,
            Rank() OVER(partition by dp.division ORDER BY SUM(fsm.sold_quantity) DESC) AS Rank_order
         FROM fact_sales_monthly fsm
         JOIN dim_product dp ON fsm.product_code = dp.product_code
         WHERE fsm.fiscal_year = 2021
         GROUP BY dp.division, fsm.product_code, dp.product
         )
 SELECT 
	division_sales.division,
    division_sales.product_code,
    division_sales.product,
    division_sales.total_sold_quantity,
    division_sales.rank_order	
 FROM division_sales
 WHERE division_sales.rank_order <= 3;