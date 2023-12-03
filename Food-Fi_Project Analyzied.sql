-- https://8weeksqlchallenge.com/case-study-3/

SELECT *
FROM plans; 

SELECT *
FROM subscriptions;

/* 											* Customer Journey *
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier! */

/* Onboarding is very simple for customers, they choose from a selection of plans based on price and content of said plans. They also have the choice to change 
there plan once they picked an initial one as well. */
SELECT customer_id, plan_name, start_date
FROM plans pla 
JOIN subscriptions sub 
	ON pla.plan_id = sub.plan_id
WHERE customer_id IN(5, 7, 10, 19, 59, 39, 74, 93, 104); 

/* Customer 5 started with a trial on August 3rd then switched to basic monthly after the 7 day period,
Customer 7 started with a trial on Feburary 2nd then switched to basic then again to pro May 22nd,
Customer 10 started with a trial on September 19th then switched to pro after 7 day period,
Customer 19 started with a trial on June 22nd then switched to pro then again to annual,
Customer 39 started with a trial on May 28 then switched to basic then again to pro August 25th and then to churn September 10,
Customer 59 started with a trial on October 30 then switched to basic then again to churn April 29th,
Customer 74 started with a trial on May 24th then switched to basic then again to annual October 1st,
Customer 93 started with a trial on March 14th then switched to pro then again to churn August 30th,
finally Customer 104 with a trial on March 29th then switched to pro after the 7 day period. */

-- 											* Data Analysis Questions *
-- 1.) How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id)
FROM subscriptions;

-- 2.) What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT MONTH(start_date) AS Month_Num, MONTHNAME(start_date) AS Month_Name, COUNT(plan_id) AS Trial_Count
FROM subscriptions
WHERE plan_id = 0
GROUP BY Month_Num, Month_Name
ORDER BY Trial_Count DESC;

-- 3.) What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT plan_name, sub.plan_id, COUNT(start_date) AS Num_Of_Subscription
FROM subscriptions sub 
JOIN plans pla 
	ON sub.plan_id = pla.plan_id
WHERE YEAR(start_date) > 2020
GROUP BY sub.plan_id, plan_name
ORDER BY sub.plan_id;

-- 4.) What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(DISTINCT customer_id) Num_of_Customer,
(SELECT COUNT(customer_id) FROM subscriptions WHERE plan_id = 4) AS Num_of_churned,
 (SELECT (CONCAT(ROUND((COUNT(customer_id) / 1000) * 100, 1), '%')) FROM subscriptions WHERE plan_id = 4) AS Percentage
FROM subscriptions;

-- 5.) How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
SELECT COUNT(customer_id) AS Num_Customers, CONCAT(ROUND(((COUNT(customer_id) / 1000) * 100)), '%') AS Percentage_Count
FROM (
	SELECT customer_id, plan_name, LEAD(plan_name) OVER() AS Next_Plan
	FROM subscriptions sub 
	JOIN plans pla 
		ON sub.plan_id = pla.plan_id ) AS Finder
WHERE plan_name = 'trial' AND Next_Plan = 'churn';

-- 6.) What is the number and percentage of customer plans after their initial free trial?
SELECT plan_name, COUNT(customer_id) AS Cust_Count,
CONCAT(ROUND(((COUNT(customer_id) / 1000) * 100)), '%') AS Percentage_Count
FROM (
    SELECT customer_id, plan_name,
	RANK() OVER(PARTITION BY customer_id ORDER BY start_date) AS Ranked 
	FROM subscriptions sub 
		JOIN plans pla 
			ON sub.plan_id = pla.plan_id ) AS Finder
WHERE Ranked = 2
GROUP BY plan_name;
        
-- 7.) What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
SELECT plan_name, COUNT(customer_id) AS Cust_Count,
CONCAT(ROUND(((COUNT(customer_id) / 1000) * 100), 1), '%') AS Percentage_Count
FROM (
    SELECT customer_id, plan_name, start_date,
    RANK() OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS Ranked 
	FROM subscriptions sub 
		JOIN plans pla 
			ON sub.plan_id = pla.plan_id
	WHERE start_date <= '2020-12-31') AS Finder
WHERE Ranked = 1
GROUP BY plan_name
ORDER BY Cust_Count DESC;

-- 8.) How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS Customer_Count
FROM subscriptions
WHERE plan_id = 3 AND YEAR(start_date) = 2020;

-- 9.) How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT ROUND(AVG(Dayer)) AS Avg_Day
FROM ( 
	SELECT ABS(DATEDIFF(sub1.start_date, sub2.start_date)) AS Dayer
	FROM subscriptions sub1
	JOIN subscriptions sub2
		ON sub1.customer_id = sub2.customer_id
		AND sub1.plan_id + 3 = sub2.plan_id
		WHERE sub2.plan_id = 3 ) AS Day_Finder;
        
-- 10.) How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT COUNT(customer_id) AS Num_of_Customers 
FROM ( 
	SELECT *, LEAD(plan_id) OVER(PARTITION BY customer_id) AS Plan_before 
	FROM subscriptions ) AS Finder  
WHERE plan_id = 2 AND Plan_before = 1 AND YEAR(start_date) = 2020;