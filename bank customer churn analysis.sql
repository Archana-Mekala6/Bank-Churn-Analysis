-- BANK CUSTOMER CHURN ANALYSIS
-- Purpose: Identify churn drivers and retention priorities
-- Dataset: Maven Analytics Bank Customer Churn (10,000 records)
create database if not exists bank_churn_data;
use bank_churn;
-- 01. TABLE INSPECTION
select count(*) as total_rows
from bank_churn;
select *
from bank_churn
limit 10;
describe bank_churn;
-- 02. DATA QUALITY CHECKS
-- Duplicate customers(expect no rows)
select 
      Customerid,
      count(*) as duplicate_count
from bank_churn
group by CustomerId
having count(*)>1;

-- Null checks(except all zeroes)
select 
     sum(CustomerId is null) as customer_nulls,
     sum(CreditScore is null) as credit_nulls,
     sum(age is null) as age_nulls,
     sum(Tenure is null) as tenure_nulls,
     sum(Balance is null) as Balance_nulls,
     sum(NumOfProducts is null) as prod_nulls,
     sum(IsActiveMember is null) as active_nulls,
     sum(Exited is null) as exited_nulls
from bank_churn;

-- Out-of-range (except no rows)
select * 
from bank_churn
where Age < 18 or Age >100
    or CreditScore<300 or CreditScore>850
    or Tenure<0;
    
-- 03. OVERALL CHURN KPIs
select 
     count(*) as total_customers,
     sum(Exited) as churned_customers,
     count(*) - sum(Exited) as retained_customers,
     round(100* sum(Exited)/count(*),2) as overall_churn_rate,
     round(sum(case when Exited=1 then Balance else 0 end),2) as churned_customer_balance
from bank_churn;
/* OUTPUT:
total_customers	churned_customers retained_customers  overall_churn_rate	churned_customer_balance
    10000	          2037	           7963	                20.37	             185588094.63
*/
-- 04. INDIVIDUAL CHURN DRIVER ANALYSIS

-- 4.1 churn by num of products         
select 
     NumOfProducts,
     count(*) as customers,
     sum(Exited) as churned_customers,
     round(100* sum(Exited)/count(*),2) as churn_rate,
     round(sum(case when Exited =1 then Balance else 0 end),2) as churned_customer_balance
from bank_churn
group by NumOfProducts
order by churn_rate desc;

-- 4.2 churn by activity status
select 
     IsActiveMember,
     count(*) as customers,
     sum(Exited) as churned_customers,
     round(100* sum(Exited)/count(*),2) as churn_rate,
     round(sum(case when Exited =1 then Balance else 0 end),2) as churned_customer_balance
from bank_churn
group by IsActivemember
order by churn_rate desc;
 
 -- 4.3 churn by gender
select 
     Gender,
     count(*) as customers,
     sum(Exited) as churned_customers,
     round(100* sum(Exited)/count(*),2) as churn_rate,
     round(sum(case when Exited =1 then Balance else 0 end),2) as churned_customer_balance
from bank_churn
group by Gender
order by churn_rate desc;

-- 4.4 churn by geography
select 
     Geography,
     count(*) as customers,
     sum(Exited) as churned_customers,
     round(100* sum(Exited)/count(*),2) as churn_rate,
     round(sum(case when Exited =1 then Balance else 0 end),2) as churned_customer_balance
from bank_churn
group by Geography
order by churn_rate desc;

-- 4.5 churn by credit card ownership
select 
     HasCrCard,
     count(*) as customers,
     sum(Exited) as churned_customers,
     round(100* sum(Exited)/count(*),2) as churn_rate,
     round(sum(case when Exited =1 then Balance else 0 end),2) as churned_customer_balance
from bank_churn
group by HasCrCard
order by churn_rate desc; 

-- Create band columns ( run once)
alter table bank_churn
add column Credit_band varchar(20),
add column Tenure_band varchar(20);

-- Disable safe update mode so UPDATE without a key works in workbench
set sql_safe_updates=0;
update bank_churn
set Credit_band = 
      case 
          when CreditScore <  580 then "Poor"
          when CreditScore < 670 then "Fair"
          when CreditScore< 740 then "Good"
          when CreditScore < 800 then "Very Good"
          else "Excellent"
	   end ;
       
       
update bank_churn
set Tenure_band=
     case 
         when Tenure <= 2 then "0-2 yrs"
         when Tenure<=4 then "3-4 yrs"
         when Tenure <=6 then "5-6 yrs"
         when Tenure <=8 then "7-8 yrs"
         else "9+ yrs"
	 end;
set sql_safe_updates=1;

  -- 4.6 churn by credit score band   
select 
     Credit_band,
     count(*) as customers,
     sum(Exited) as churned_customers,
     round(100* sum(Exited)/count(*),2) as churn_rate,
     round(sum(case when Exited =1 then Balance else 0 end),2) as churned_customer_balance
     
from bank_churn
group by Credit_band
order by churn_rate desc;

-- 4.7 churn by tenure band
select 
     Tenure_band,
     count(*) as customers,
     sum(Exited) as churned_customers,
     round(100* sum(Exited)/count(*),2) as churn_rate,
     round(sum(case when Exited =1 then Balance else 0 end),2) as churned_customer_balance
from bank_churn
group by Tenure_band
order by churn_rate desc;
        
-- 05. PRIORITY SEGMENT ANALYSIS
-- (segment overlaps; they are not mutually exclusive groups)

-- 5.1 Priority segment: Inactive customers with one product 
select 
     count(*) as customers,
     sum(Exited=1) as churned_customers,
     round(100*sum(Exited=1)/count(*),2) as churn_rate,
     round(sum(case when Exited=1 then Balance else 0 end),2) as churned_customer_balance
from bank_churn
where IsActiveMember=0
  and NumOfProducts=1;
/* OUTPUT:
customers	churned_customers	churn_rate	churned_customer_balance
  2521	          924	           36.65	     85021901.83
*/  
           
-- 5.2 Geographic priority: Germany customers with one product
select 
     count(*) as customers,
     sum(Exited=1) as churned_customers,
     round(100*sum(Exited=1)/count(*),2) as churn_rate,
     round(sum(case when Exited=1 then Balance else 0 end),2) as churned_customer_balance
from bank_churn
where Geography="Germany"
  and NumOfProducts=1;  
/* OUTPUT:
customers	churned_customers	churn_rate	churned_customer_balance
  1349	           578	           42.85	      69725167.5
*/  

-- 5.3 Supporting drill-down: Germany, inactive, one product
select 
     count(*) as customers,
     sum(Exited=1) as churned_customers,
     round(100*sum(Exited=1)/count(*),2) as churn_rate,
     round(sum(case when Exited=1 then Balance else 0 end),2) as churned_customer_balance
from bank_churn
where Geography="Germany"
  and IsActiveMember=0
  and NumOfProducts=1; 
/* OUTPUT:
customers	churned_customers	churn_rate	churned_customer_balance
   720	           375	           52.08	      45222370.17
*/  

-- 06.FINAL BUSINESS INSIGHTS AND RECOMMENDATIONS
/*
OVERALL FINDING:
- Total customers: 10,000
- Churned customers: 2,037
- Overall churn rate: 20.37%
- Balance held by churned customers: approx. 185.6M
KEY FINDING 1: INACTIVE CUSTOMER WITH ONE PRODUCT
- Customers: 2,521
- churn rate: 36.65%
- Churned-customer balance: approx. 85.0M
KEY FINDING 2: GERMANY+ ONE PRODUCT
- Customers: 1349
- churn rate: 42.85%
- churned-customer balance: approx. 69.7M
SUPPORTING DRILL-DOWN: GERMANY + INACTIVE + ONE PRODUCT
- Customers: 720
- churn rate: 52.08%
- churned-customer balance: approx. 45.2M
BUSINESS RECOMMENDATION:
Prioritise re-engagement of inactive customers with one product, starting with the high-churn Germany subgroup.
Test targeted retention initiatives and monitor subsequent churn to assess whether the interventions are effective.
NOTE:Churned-customer balances describe balances held by customers who left.
They are not direct financial losses.
*/
-- 07.VIEWS FOR POWER BI
create or replace  view bank_churn_analysis as 
select 
      CustomerId,
      CreditScore,
      Geography,
      Gender,
      Age,
      Tenure,
      Balance,
      NumOfProducts,
      HasCrCard,
      IsActiveMember,
      Exited,
      Credit_band,
      Tenure_Band
from bank_churn;

create or replace view retention_priority as
select 
      "Inactive + 1 Product" as Priority_Segment,
      count(*) as Total_Customers,
      sum(Exited=1) as Churned_Customers,
      sum(Exited=0) as Retained_customers,
      round(sum(Exited=1)/count(*),4) as Churn_Rate,
      round(sum(case when Exited =1 then Balance else 0 end),2) as Churned_Customer_Balance
from bank_churn
where IsActiveMember=0
    and NumOfProducts=1
union all 
select
     "Germany + 1 Product", 
      count(*),
      sum(Exited=1),
      sum(Exited=0),
      round(sum(Exited=1)/count(*),4),
      round(sum(case when Exited =1 then Balance else 0 end),2) 
from bank_churn
where Geography="Germany"
    and NumOfProducts=1
union all
select
     "Germany + Inactive + 1 Product", 
      count(*),
      sum(Exited=1),
      sum(Exited=0),
      round(sum(Exited=1)/count(*),4),
      round(sum(case when Exited =1 then Balance else 0 end),2) 
from bank_churn
where Geography="Germany"
    and IsActiveMember=0
    and NumOfProducts=1;

select * from retention_priority;
