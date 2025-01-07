create database project1
use project1

select * from dbo.product
select * from dbo.customer
select * from dbo.[transaction]

--  Data preparation and understanding


--Q1:What is the total number of rows in each of the 3 tables in the database?


select 'Total_Transaction' ,  count(*) from dbo.[transaction]
union
select 'Total_Customer' , count(*) from dbo.customer
union
select 'Total_Product' , count(*) from dbo.product


--Q2:What is the total number of transactions that have a return?


select count(*) as Total_returned from dbo.[transaction]
where qty<0


--Q3:As you would have noticed, the dates provided across the datasets are
--not in a correct format. As first steps, pls convert the date variables into
--valid date formats before proceeding ahead.


--Customer table
select convert (date,DOB,105) as NEW_DOB from dbo.[customer]

update dbo.[customer]
set DOB=convert (date,DOB,105)

alter table dbo.[customer]
alter column DOB date

--Transaction table
select convert(date,tran_date,105) from dbo.[transaction]

update dbo.[transaction]
set tran_date=convert(date,tran_date,105)

alter table dbo.[transaction]
alter column tran_date date


--Q4:What is the time range of the transaction data available for analysis? 
--Show the output in number of days, months and years simultaneously in different columns.


select DATEDIFF(day,tran_date,GETDATE()) as 'DAY',
DATEDIFF(month,tran_date,GETDATE()) as 'MONTH',
DATEDIFF(year,tran_date,GETDATE()) as 'YEAR' from dbo.[transaction]


--Q5:Which product category does the sub-category “DIY” belong to?


select prod_cat from dbo.product
where prod_subcat='DIY'


--DATA ANALYSIS


--Q1:Which channel is most frequently used for transactions?


select top 1 Store_type,count(transaction_id) as total from dbo.[transaction]
group by Store_type
order by total desc


--Q2:What is the count of Male and Female customers in the database?


select gender , count(customer_Id) from dbo.customer
group by gender
having Gender='M' or gender='F'


--Q3:From which city do we have the maximum number of customers and how many?


alter table dbo.customer
alter column city_code int

select top 1 city_code , count(customer_Id) as total_people from dbo.customer
group by city_code
order by total_people desc


--Q4:How many sub-categories are there under the Books category?


select count(prod_subcat) as total_subcat_book from 
(
select prod_cat , prod_subcat from dbo.product
group by prod_cat , prod_subcat
having prod_cat='books') as a


--Q5:What is the maximum quantity of products ever ordered?


select * from dbo.[transaction]
where qty = 5 or qty=-5


--Q6:What is the net total revenue generated in categories Electronics and Books?


alter table dbo.[transaction]
alter column total_amt float

select prod_cat , sum(total_amt) as total_revenue from dbo.[transaction] as a
inner join dbo.product as b
on a.prod_subcat_code=b.prod_sub_cat_code
and a.prod_cat_code=b.prod_cat_code
where prod_cat in ('books', 'electronics') and total_amt>0
group by prod_cat


--Q7:How many customers have >10 transactions with us, excluding returns?


select cust_id , count(cust_id) as total_cust from dbo.[transaction]
where qty>0
group by cust_id
having count(cust_id)>10


--Q8:What is the combined revenue earned from the “Electronics” & “Clothing” categories,
--from “Flagship stores”?


select sum(total_amt) as total_revenue from dbo.[transaction]
where prod_cat_code in (select distinct prod_cat_code from dbo.product
where prod_cat in ('clothing' , 'electronics')) and Store_type='flagship store' and qty>0


--Q9:What is the total revenue generated from “Male” customers in “Electronics” category?
--Output should display total revenue by prod sub-cat.


select prod_subcat , sum(total_amt) as total_revenue from dbo.[transaction] as a
inner join dbo.customer as b
on a.cust_id=b.customer_Id
inner join dbo.product as c
on a.prod_cat_code=c.prod_cat_code
and a.prod_subcat_code=c.prod_sub_cat_code
where gender='m' and a.prod_cat_code=(select distinct prod_cat_code from dbo.product
where prod_cat='electronics') and Qty>0
group by prod_subcat


--Q10:What is percentage of sales and returns by product sub category; 
--display only top 5 sub categories in terms of sales?


select top 5 prod_subcat , 
sum(cast(case when Qty > 0 then Qty else 0 end as float)) as Total_sales , 
-sum(cast(case when Qty < 0 then Qty else 0 end as float)) as Total_returns ,
(sum(cast(case when Qty > 0 then Qty else 0 end as float))-sum(cast(case when Qty < 0 then Qty else 0 end as float))) as Total_ ,
round((sum(cast(case when Qty > 0 then Qty else 0 end as float)))/(sum(cast(case when Qty > 0 then Qty else 0 end as float))-sum(cast(case when Qty < 0 then Qty else 0 end as float)))*100,2) as Percent_sales ,
round((-sum(cast(case when Qty < 0 then Qty else 0 end as float)))/(sum(cast(case when Qty > 0 then Qty else 0 end as float))-sum(cast(case when Qty < 0 then Qty else 0 end as float)))*100,2) as Percent_returns
from dbo.[transaction] as a
inner join dbo.product as b
on a.prod_cat_code=b.prod_cat_code
and a.prod_subcat_code=b.prod_sub_cat_code
group by prod_subcat 
order by Percent_sales desc


--Q11:For all customers aged between 25 to 35 years find what is the net total revenue
--generated by these consumers in last 30 days of transactions from max transaction date 
--available in the data?


SELECT Customer_id,
DATEDIFF(YY,CONVERT(DATE,DOB,103),GETDATE()) AS [Customer converted Age],
sum(cast(T.total_amt as float)) as [Total revenue] FROM dbo.customer C
inner JOIN dbo.[transaction] T
ON C.CUSTOMER_ID = T.cust_id
WHERE cust_id in( select customer_Id from customer where DATEDIFF(Year,CONVERT(DATE,DOB,103),GETDATE()) BETWEEN 25 AND 35) and
datediff(day,CONVERT(DATE,tran_date,103),(select max(tran_date) from dbo.[transaction])) <=30
GROUP BY DATEDIFF(YY,CONVERT(DATE,DOB,103),GETDATE()),customer_Id
order by [Total revenue] desc;


--Q12:Which product category has seen the max value of returns in the last 3 months of transactions?


select top 1 prod_cat , 
sum(total_amt) as Max_value
from dbo.[transaction] as a
inner join dbo.product as b
on a.prod_cat_code=b.prod_cat_code
and a.prod_subcat_code=b.prod_sub_cat_code
where qty<0 and datediff(month,tran_date,(select max(tran_date) from dbo.[transaction]))<=3
group by prod_cat


--Q13:Which store-type sells the maximum products; by value of sales amount and by quantity sold?


alter table dbo.[transaction]
alter column Qty int
select top 1 store_type , sum(Qty) as Total_quantity,sum(total_amt) as Total_sales from dbo.[transaction]
group by Store_type
order by Total_quantity desc , Total_sales desc


--Q14:What are the categories for which average revenue is above the overall average.


select prod_cat, avg(total_amt) as Avg_ from dbo.[transaction] as a
inner join dbo.product as b
on a.prod_cat_code=b.prod_cat_code
and a.prod_subcat_code=b.prod_sub_cat_code
group by prod_cat
having avg(total_amt)>(select avg(total_amt) from dbo.[transaction])


--Q15:Find the average and total revenue by each subcategory for the categories which are among 
--top 5 categories in terms of quantity sold.


select prod_cat , prod_subcat, avg(total_amt) as Avg_ , sum(total_amt) as Total_ from dbo.[transaction] as a
inner join dbo.product as b
on a.prod_cat_code=b.prod_cat_code
and a.prod_subcat_code=b.prod_sub_cat_code
where prod_cat in (select prod_cat from (
select top 5 prod_cat, sum(Qty) as sold from dbo.[transaction] as a
inner join dbo.product as b
on a.prod_cat_code=b.prod_cat_code
and a.prod_subcat_code=b.prod_sub_cat_code
group by prod_cat
order by sold desc
) as c)
group by prod_cat , prod_subcat

 










