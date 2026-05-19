create database ecommerce_analysis;

use ecommerce_analysis;

create table retail_raw (
	invoice varchar(20), 
    stockCode varchar(20), 
    description varchar(255), 
    quantity int,
    invoiceDate varchar(50), 
    price decimal(10,2), 
    customerID varchar(20), 
    country varchar(100)
);

-- Load the dataset into the table
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/online_retail.csv'
into table retail_raw character set latin1
fields terminated by ',' enclosed by '"' lines terminated by '\n'
ignore 1 rows;

-- Create another table for cleaning data
create table retail_clean like retail_raw;
insert into retail_clean select * from retail_raw;
describe retail_clean;
update retail_clean set country = trim(country);
update retail_clean set country = replace(country, '\r', '');
alter table retail_clean add column totalPrice decimal(10,2);
update retail_clean set totalPrice = price * quantity;

-- Data Cleaning

-- Remove Cancelled Orders
delete from retail_clean where invoice like 'C%';
-- Remove null IDs
delete from retail_clean where customerID is null or customerID = '';
-- Remove 0 or -ve prices
delete from retail_clean where quantity <= 0 or price <= 0;
-- Remove null descriptions
delete from retail_clean where description is null or description = '';


-- Exploratory Data Analysis

-- Monthly Revenues
select date_format(str_to_date(invoiceDate, '%d-%m-%Y %H:%i'), '%Y-%m') as month, 
	round(sum(totalPrice), 2) as monthlyRevenue
    from retail_clean group by month order by month;
    
-- Top 10 best selling products
select row_number() over (order by sum(quantity) desc) as serialNo, 
description, sum(quantity) as totalUnitsSold, round(sum(totalPrice), 2) as totalRevenue from retail_clean
group by description order by totalUnitsSold desc limit 10;

-- Top 10 countries based on revenue
select row_number() over (order by sum(totalPrice) desc) as serialNo,
country, round(sum(totalPrice), 2) as totalRevenue, count(*) from retail_clean
group by country order by totalRevenue desc limit 10;

-- Avg Order Value of invoices
select avg(OrderValue) from (
	select sum(totalPrice) as OrderValue from retail_clean group by invoice ) as avgOrder;
    
-- Month over month revenue growth
with monthlyRevenue as (
	select date_format(str_to_date(invoiceDate, '%d-%m-%Y %H:%i'), '%Y-%m') as month,
    round(sum(totalPrice), 2) as revenue from retail_clean group by month)
select month, revenue, lag(revenue) over (order by month) as prevMonthRevenue, 
	round((revenue-lag(revenue) over (order by month)) / lag(revenue) over (order by month) * 100, 2) as growthPercentage
    from monthlyRevenue order by month;
    
-- Top 3 porducts per country
with productRank as (
	select country, description, round(sum(totalPrice), 2) as revenue, rank() over (partition by country order by sum(totalPrice) desc) as rnk
    from retail_clean group by country, description)
select country, rnk, description, revenue from productRank  where rnk <= 3  order by country, rnk;

-- RFM customer segmentation
with rfm_base as (
	select customerID, datediff(max(str_to_date(invoiceDate, '%d-%m-%Y %H:%i')), min(str_to_date(invoiceDate, '%d-%m-%Y %H:%i'))) as recency,
    count(distinct invoice) as frequency, round(sum(totalPrice), 2) as monetary 
    from retail_clean group by customerID), 
rfm_scored as (
	select *,
	case when recency < 30 then 'High' when recency < 90 then 'Medium' else 'Low' end as recencyScore,
	case when frequency >= 10 then 'High' when frequency >= 4 then 'Medium' else 'Low' end as frequencyScore,
	case  when monetary >= 1000 then 'High' when monetary >= 300 then 'Medium' else 'Low' end as monetaryScore
	from rfm_base)
select * from rfm_scored order by monetary desc limit 50;
    
-- repeat vs one-time customers
select customerType, count(*) as customerCount, count(*) * 100.0 / sum(count(*)) over() as percentage
from (
	select customerID, case when count(distinct invoice) = 1 then 'One-Time' else 'Repeat' end as customerType
	from retail_clean group by customerID) 
as customerTypes group by customerType;
    
-- Stored procedure
-- return top 5 customers of each country based on total revenue
set sql_safe_updates = 0;
delimiter $$
create procedure top5CustomersByCountry(in p_country varchar(100))
begin
	select customerID, country, count(distinct invoice) as totalOrders, sum(totalPrice) as totalSpent from retail_clean
    where country = p_country group by customerID, country order by totalSpent desc limit 5;
end $$
delimiter ;

call top5CustomersByCountry('United Kingdom');

set sql_safe_updates = 1;
