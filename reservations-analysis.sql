-- Check if tables are loaded properly
select * from dbo.['2018$'];
select * from dbo.['2019$'];
select * from dbo.['2020$'];
select * from dbo.meal_cost$;
select * from dbo.market_segment$;


-- Union all years with CTE to make it easier to query
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
)

select count(*) from reservations;


-- Q1. Find trends for booking seasonality
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
)

select
	arrival_date_month,
	round(
		count(*) * 100.0 / (select count(*) from reservations)
	, 2) as booking_percentage
from reservations
group by arrival_date_month
order by booking_percentage desc;


-- Q2. What is demography of the customers? Citizens of which countries are visiting these hotels most?
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
)

select top 10
	country,
	count(*) as total_count
from reservations
group by country
order by total_count desc;


-- Q3. What is the most popular meal type ordered by customers?
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
)

select
	r.meal,
    mc.meal_cost,
	count(*) as meal_count,
from reservations as r
left join dbo.meal_cost$ as mc on
	r.meal = mc.meal
group by r.meal, mc.meal_cost
order by meal_count desc


-- Q4. What channels customers are using to make reservations?
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
)

select
    distribution_channel,
    round(
	    count(*) * 100.0 / (select count(*) from reservations)
    , 2) as channel_percentage
from reservations
group by distribution_channel
order by channel_percentage desc;


-- We can also look at the output segemented by hotel type to see if we can get any different insight.
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
),
hotel_type_count as (
	select hotel_type, count(*) as count from reservations
	group by hotel_type
)

select
	hotel_type,
    distribution_channel,
	round(
		count(*) * 100.0 /
		 (select hotel_type_count.count
		  from hotel_type_count
		  where reservations.hotel_type = hotel_type_count.hotel_type)
	, 2) as channel_percentage
from reservations
group by hotel_type, distribution_channel
order by hotel_type, channel_percentage desc;


-- Q5. What is the cancellation rate? Which distribution channels have more cancellations? Find trend for this month over month
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
)

select
	round(
		sum(is_canceled) * 100.0 / count(*)
	, 2) as cancel_percentage
from reservations;

-- by hotel type
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
)

select
	hotel_type,
	round(
		sum(is_canceled) * 100.0 / count(*)
	, 2) as cancel_percentage
from reservations
group by hotel_type
order by hotel_type, cancel_percentage desc;


-- by hotel type and distribution channels
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
),
hotel_type_count as (
	select hotel_type, count(*) as total_count, sum(is_canceled) as canceled_count from reservations
	group by hotel_type
)

select
	hotel_type,
    distribution_channel,
	round(
		sum(is_canceled) * 100.0 /
		 (select hotel_type_count.canceled_count
		  from hotel_type_count
		  where reservations.hotel_type = hotel_type_count.hotel_type)
	, 2) as cancel_percentage
from reservations
group by hotel_type, distribution_channel
order by hotel_type, cancel_percentage desc;


-- Cancellatiom percentage across months
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
)

select
	arrival_date_month,
	round(
		sum(is_canceled) * 100.0 / count(*)
	, 2) as cancel_percentage
from reservations
group by arrival_date_month
order by cancel_percentage desc;


-- Q6. What is the revenue for these hotels? Segment by year and type of hotel
with reservations as (
    select * from dbo.['2018$']
    union
    select * from dbo.['2019$']
    union
    select * from dbo.['2020$']
)

select
    arrival_date_year,
    hotel_type,
    round(
        sum((stays_in_week_nights + stays_in_weekend_nights) * (adr * (1 - discount)))
    , 2) as revenue
from reservations as r
left join dbo.market_segment$ as ms
    on r.market_segment = ms.market_segment
group by is_canceled, arrival_date_year, hotel_type
having is_canceled = 0
order by arrival_date_year, hotel_type