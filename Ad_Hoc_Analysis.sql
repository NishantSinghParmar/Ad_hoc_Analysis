------------ Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.---------------------------
SELECT market  FROM dim_customer
where customer = "Atliq Exclusive" and region = "APAC";


------------ What is the percentage of unique product increase in 2021 vs. 2020?------------------------------------------------------------------
with product_2020 as (
	select count( distinct product_code) as unique_products_2020
	from fact_sales_monthly
	where fiscal_year = 2020
),
 product_2021 as (
	select count( distinct product_code) as unique_products_2021
	from fact_sales_monthly
	where fiscal_year = 2021
)
select unique_products_2020,unique_products_2021,
		(unique_products_2021-unique_products_2020)*100/unique_products_2020 as percentage_chg
        from product_2020,product_2021;
        
        
------------ Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. ----------------

SELECT 
    segment, COUNT(DISTINCT product_code) AS product_counts
FROM
    dim_product
GROUP BY segment
ORDER BY product_counts DESC;


------------ Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?--------------------------------------------------------

with product_2020 as (
	select dp.segment, count( distinct s.product_code) as count_2020
	from fact_sales_monthly s 
    join dim_product dp on s.product_code=dp.product_code
	where s.fiscal_year = 2020
    group by dp.segment
),
 product_2021 as (
	select dp.segment, count( distinct s.product_code) as count_2021
	from fact_sales_monthly s 
    join dim_product dp on s.product_code=dp.product_code
	where s.fiscal_year = 2021
    group by dp.segment
),
increase as (
		select p20.segment,p20.count_2020 as product_count_2020,p21.count_2021 as product_count_2021,(p21.count_2021-p20.count_2020) as difference
        from product_2020 p20
        join product_2021 p21 on p20.segment = p21.segment
)

select segment,product_count_2020,product_count_2021 
        ,difference
from increase
order by difference desc
limit 1;



--------------------  Get the products that have the highest and lowest manufacturing costs.-------------------------------------------------------

with min_max as (
	select min(manufacturing_cost) as min_cost, max(manufacturing_cost) as max_cost
    from fact_manufacturing_cost)
    
select dp.product_code,dp.product,mc.manufacturing_cost
from dim_product dp
join fact_manufacturing_cost mc on  dp.product_code=mc.product_code
where mc.manufacturing_cost= (select max_cost from min_max)

union all

select dp.product_code,dp.product,mc.manufacturing_cost
from dim_product dp
join fact_manufacturing_cost mc on  dp.product_code=mc.product_code
where mc.manufacturing_cost= (select min_cost from min_max);


---- Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
        
select dc.customer_code as customer_code ,dc.customer as customer, avg(pid.pre_invoice_discount_pct) as average_discount_percentage
from dim_customer dc
join fact_pre_invoice_deductions pid on dc.customer_code=pid.customer_code
where pid.fiscal_year = 2021 and dc.sub_zone = "India"
group by dc.customer_code, dc.customer
order by average_discount_percentage desc
limit 5;


--------- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
--------- high-performing months and take strategic decisions.

with Gross_Sales as (
SELECT 
    MONTH(s.date) AS Month,
    s.fiscal_year AS Year,
    (s.sold_quantity * gp.gross_price) AS GSA
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price gp ON s.product_code = gp.product_code
        AND s.fiscal_year = gp.fiscal_year
        JOIN
    dim_customer dc ON s.customer_code = dc.customer_code
WHERE
    dc.customer = 'Atliq Exclusive'
)
select Month,Year, round(sum(GSA),2) as Gross_sales_Amount
from Gross_Sales
group by Month , Year;


--------- In which quarter of 2020, got the maximum total_sold_quantity? ----------------------------------


SELECT 
    QUARTER(DATE_ADD(date, INTERVAL 4 MONTH)) AS quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = '2020'
GROUP BY quarter
order by total_sold_quantity desc
limit 1;


--------- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? ---------------------------------

with cte_1 as (
SELECT 
    dc.channel as channel,
    (s.sold_quantity * gp.gross_price) AS gross_sales  
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price gp ON s.product_code = gp.product_code
        AND s.fiscal_year = gp.fiscal_year
        JOIN
    dim_customer dc ON s.customer_code = dc.customer_code
WHERE
    s.fiscal_year = '2021'
),
cte_2 as (	
	select sum(gross_sales ) as total_gross_sales_mln
	from cte_1
)
	select channel,sum(gross_sales) as gross_sales_mln,sum((gross_sales /total_gross_sales_mln)*100) as percentage
    from cte_1,cte_2
    group by channel
    order by gross_sales_mln desc;
    
    
    ------------ Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? -------------------------

with cte_1 as(
select dp.division,dp.product_code,dp.product,sum(s.sold_quantity) as total_sold_quantity,
		RANK() OVER(PARTITION BY division ORDER BY sum(s.sold_quantity) DESC) as rank_order
from dim_product dp
join fact_sales_monthly s on dp.product_code=s.product_code
where s.fiscal_year= '2021'
group by dp.division,dp.product_code,dp.product
)

select division,product_code,product,total_sold_quantity,rank_order
from cte_1
WHERE 
    rank_order <= 3;

