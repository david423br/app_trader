-- 1. Loading the data
-- 	a. Launch PgAdmin and create a new database called app_trader.

-- 	b. Right-click on the app_trader database and choose Restore...

-- 	c. Use the default values under the Restore Options tab.

-- 	d. In the Filename section, browse to the backup file app_store_backup.backup in the data folder of this repository.

-- 	e. Click Restore to load the database.

-- 	f. Verify that you have two tables:
-- 		- app_store_apps with 7197 rows
-- 		- play_store_apps with 10840 rows

SELECT *
FROM app_store_apps;

SELECT * 
FROM play_store_apps;

-- 2. Assumptions
-- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- 	a. David - App Trader will purchase the rights to apps for 10,000 times the list price of the app on the Apple App Store/Google Play Store, however the minimum price to purchase the rights to an app is $25,000. For example, a $3 app would cost $30,000 (10,000 x the price) and a free app would cost $25,000 (The minimum price). NO APP WILL EVER COST LESS THEN $25,000 TO PURCHASE.

SELECT *
FROM app_store_apps
FULL JOIN play_store_apps
USING(rating);

WITH unioned_table AS	((SELECT
							name,
							size,
							price::MONEY::NUMERIC,
							review_count,
							rating,
							content_rating,
							genres
						FROM play_store_apps)
						UNION ALL
						(SELECT
							name,
							size_bytes,
							price,
							review_count::NUMERIC,
							rating,
							content_rating,
							primary_genre
						FROM app_store_apps))
SELECT
	name,
	price,
	CASE	WHEN price <= 2.5 THEN 25000
			ELSE price * 10000 END AS app_price
FROM unioned_table;

SELECT *
FROM app_store_apps;

-- 	b. Matthew - Apps earn $1000 per rating point on average from in-app purchases per platform.  An app with 1.5 rating would earn $1500/month while a 4-star app would earn $4000/month.

WITH unioned_table AS	((SELECT
							name,
							size,
							price::MONEY::NUMERIC,
							review_count,
							rating,
							content_rating,
							genres
						FROM play_store_apps)
						UNION ALL
						(SELECT
							name,
							size_bytes,
							price,
							review_count::NUMERIC,
							rating,
							content_rating,
							primary_genre
						FROM app_store_apps))
SELECT
	name,
	price,
	CASE	WHEN price <= 2.5 THEN 25000
			ELSE price * 10000 END AS app_price,
	-- AVG(rating) AS avg_rating,
	rating * 1000 AS in_app_per_month
FROM unioned_table
WHERE rating IS NOT NULL;
-- GROUP BY price, app_price, avg_rating, in_app_per_month;

WITH unioned_table AS	((SELECT
							name,
							size,
							price::MONEY::NUMERIC,
							review_count,
							rating,
							content_rating,
							genres
						FROM play_store_apps)
						UNION ALL
						(SELECT
							name,
							size_bytes,
							price,
							review_count::NUMERIC,
							rating,
							content_rating,
							primary_genre
						FROM app_store_apps))
SELECT 
	name,
	AVG(rating) AS avg_rating
FROM unioned_table
WHERE rating IS NOT NULL
GROUP BY name;

SELECT a.name, FLOOR(ROUND(((SUM(DISTINCT(a.rating + (p.rating))))/2)*2/0.25)*0.25) AS avg_rating
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
USING(name)
GROUP BY a.name;

SELECT a.name,1+ FLOOR(ROUND(((SUM(DISTINCT(a.rating + (p.rating))))/2)/0.25)*0.25) AS avg_rating
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
USING(name)
GROUP BY a.name;

SELECT a.name, ((((SUM(DISTINCT(a.rating + (p.rating))))/2))/.25)::integer * .25 AS avg_rating
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
USING(name)
GROUP BY a.name;

-- 	c. Anagha - App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.

WITH unioned_table AS	((SELECT
							name,
							size,
							price::MONEY::NUMERIC,
							review_count,
							rating,
							content_rating,
							genres
						FROM play_store_apps)
						UNION ALL
						(SELECT
							name,
							size_bytes,
							price,
							review_count::NUMERIC,
							rating,
							content_rating,
							primary_genre
						FROM app_store_apps))
SELECT
	name,
	price,
	CASE	WHEN price <= 2.5 THEN 25000
			ELSE price * 10000 END AS app_price,
	rating,
	rating * 1000 AS in_app_per_month,
	'1000' AS ad_cost
FROM unioned_table;

-- 	d. Arin - For every quarter-point that an app gains in rating, its projected lifespan increases by 6 months, in other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years. Ratings should be rounded down to the nearest 0.25 to evaluate an app's likely longevity.   

WITH unioned_table AS	((SELECT
							name,
							size,
							price::MONEY::NUMERIC,
							review_count,
							rating,
							content_rating,
							genres
						FROM play_store_apps)
						UNION
						(SELECT
							name,
							size_bytes,
							price,
							review_count::NUMERIC,
							rating,
							content_rating,
							primary_genre
						FROM app_store_apps))
SELECT
	name,
	(AVG(t1.rating)/.25)::integer*.25 AS t1_avg_rating,
	AVG(t1.rating) AS actual_avg_rating,
	price,
	((((AVG(t1.rating)/.25)::integer*.25)*2)+1) AS years_viable,
	ROUND(((((((AVG(t1.rating)/.25)::integer*.25)*2)+1)*12)*1000),2)::money AS marketing_cost,
	((AVG(t1.rating)/.25)::integer*.25)*1000::money AS rating_value,
	CASE	WHEN price <= 2.5 THEN 25000::money
				ELSE price * 10000::money END AS app_price,
	(((((AVG(t1.rating)/.25)::integer*.25)*2)+1)*12)*(((AVG(t1.rating)/.25)::integer*.25)*1000)::money AS in_app_sales_exp,
	((((AVG(t1.rating))*2)+1)*12)*(((AVG(t1.rating)/.25)::integer*.25)*1000)::money AS in_app_sales_exp_actual
	-- (((((AVG(t1.rating)/.25)::integer*.25)*2)+1)*12)*(((AVG(t1.rating)/.25)::integer*.25)*1000)
	-- -(ROUND(((((((AVG(t1.rating)/.25)::integer*.25)*2)+1)*12)*1000),2))
	-- -(CASE	WHEN price <= 2.5 THEN 25000 ELSE price * 10000 END)::money AS profit_expected
FROM unioned_table AS t1
WHERE rating IS NOT NULL
GROUP BY name, price;

WITH unioned_table AS	((SELECT
							name,
							size,
							price::MONEY::NUMERIC,
							review_count,
							rating,
							content_rating,
							genres
						FROM play_store_apps)
						UNION ALL
						(SELECT
							name,
							size_bytes,
							price,
							review_count::NUMERIC,
							rating,
							content_rating,
							primary_genre
						FROM app_store_apps))
SELECT
	name,
	AVG(t1.rating) AS actual_avg_rating,
	(AVG(t1.rating)/.25)::integer*.25 AS rounded_avg_rating,
	price,
	((((AVG(t1.rating)/.25)::integer*.25)*2)+1) AS years_viable,
	ROUND(((((((AVG(t1.rating)/.25)::integer*.25)*2)+1)*12)*1000),2)::money AS marketing_cost,
	((((AVG(t1.rating)/.25)::integer*.25)*1000)*12)::money AS rating_value_by_year,
	CASE	WHEN price <= 2.5 THEN 25000::money
			ELSE price * 10000::money END AS app_price,
	(((((AVG(t1.rating)/.25)::integer*.25)*1000)*12)::money)*((((AVG(t1.rating)/.25)::integer*.25)*2)+1) AS in_app_sales,
	(ROUND(((((((AVG(t1.rating)/.25)::integer*.25)*2)+1)*12)*1000),2)::money)+(CASE	WHEN price <= 2.5 THEN 25000::money
																				ELSE price * 10000::money END) AS total_cost,
	(((((AVG(t1.rating))*2)+1)*12)*(((AVG(t1.rating)/.25)::integer*.25)*1000)::money)-((ROUND(((((((AVG(t1.rating)/.25)::integer*.25)*2)+1)*12)*1000),2)::money)+
	(CASE	WHEN price <= 2.5 THEN 25000::money ELSE price * 10000::money END)) AS total_earnings
FROM unioned_table AS t1
WHERE rating IS NOT NULL
GROUP BY name, t1.price
ORDER BY total_earnings DESC;

SELECT *
FROM play_store_apps
WHERE rating >= 5;

SELECT *
FROM app_store_apps
WHERE rating >= 5;

WITH unioned_table AS	((SELECT
							name,
							size,
							price::MONEY::NUMERIC,
							review_count,
							rating,
							content_rating,
							genres
						FROM play_store_apps)
						UNION ALL
						(SELECT
							name,
							size_bytes,
							price,
							review_count::NUMERIC,
							rating,
							content_rating,
							primary_genre AS genres
						FROM app_store_apps))
SELECT DISTINCT genres
FROM unioned_table
ORDER BY genres;

SELECT
	p.name AS name,
	p.size AS play_size,
	a.size_bytes AS apple_size,
	p.price::MONEY::NUMERIC AS play_price,
	CASE	WHEN p.price::MONEY::NUMERIC <= 2.5 THEN 25000
			ELSE p.price::MONEY::NUMERIC * 10000 END AS play_app_price,
	a.price AS apple_price,
	CASE	WHEN a.price <= 2.5 THEN 25000
			ELSE a.price * 10000 END AS apple_app_price,
	p.review_count AS play_review_count,
	a.review_count::NUMERIC AS apple_review_count,
	p.rating AS play_rating,
	p.rating * 1000 AS play_in_app_per_month,
	a.rating::FLOAT AS apple_rating,
	a.rating * 1000 AS apple_in_app_per_month,
	-- ((((SUM(DISTINCT(a.rating + (p.rating))))/2))/.25)::integer * .25 AS avg_rating,
	'1000' AS ad_cost,
	p.content_rating AS play_content_rating,
	a.content_rating AS apple_content_rating,
	p.genres AS play_genre,
	a.primary_genre AS apple_genre
FROM play_store_apps AS p
FULL JOIN app_store_apps AS a
	USING(name);
GROUP BY p.name, p.price, a.price, play_rating, play_in_app_per_month, apple_rating, apple_in_app_per_month, ad_cost, play_genre, apple_genre;
GROUP BY p.name, play_size, apple_size, p.price, a.price, play_review_count, apple_review_count, play_rating, play_in_app_per_month, apple_rating, apple_in_app_per_month, ad_cost, play_content_rating, apple_content_rating, play_genre, apple_genre;

-- 	e. Team - If an app is on both platforms it could have 2 different ratings.  In this case you can take the average rounded down to the nearest .25.

SELECT COUNT(rating) AS count_rating
FROM app_store_apps
WHERE rating IS NOT NULL
	AND rating > 0;

SELECT *
FROM app_store_apps;




-- 3. Deliverables
-- 	a. Develop some general recommendations about the price range, genre, content rating, or any other app characteristics that the company should target.

-- - "Games" apps dominate the high earner bracket. 
-- - Domino's pizza is the only "Food & Drink" app until row 170.
-- - Apps with "content_rating" age 4+ leave higher rating/reviews in higher volume than other "content_rating" categories.
-- - If you want to diversify your portfolio you cold get 10 apps, all from different Genres, and you would still be purchasing within the top 41 earning apps.
-- - 

-- 	b. Develop a Top 10 List of the apps that App Trader should buy based on profitability/return on investment as the sole priority.

-- TOP 10
-- - Head Soccer
-- - Plants vs. Zombies
-- - Sniper 3D Assassin: Shoot to Kill Gun Game
-- - Geometry Dash Lite
-- - Infinity Blade
-- - Geometry Dash
-- - Domino's Pizza USA
-- - CSR Racing USA
-- - Pictoword: Fun 2 Pics Guess What's the Word Trivia
-- - Plants vs. Zombies HD

-- 	c. Develop a Top 4 list of the apps that App Trader should buy that are profitable but that also are thematically appropriate for the upcoming Halloween themed campaign.

Top 4 Halloween themed campaign
- Plants vs. Zombies
- Flashlight
- Ghost Lens+Scary Photo Video Edit & Collage Maker
- Infect Them All 2 : Zombies
- Infect Them All : Vampires
- Rusty Lake Hotel
- Halloween Makeover: Spa, Makeup & Dressup Salon
- HauntedPic
- Severed

-- 	d. Submit a report based on your findings. The report should include both of your lists of apps along with your analysis of their cost and potential profits. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for your report.

WITH unioned_table AS	((SELECT
							name,
							size,
							price::MONEY::NUMERIC,
							review_count,
							rating,
							content_rating,
							genres
						FROM play_store_apps)
						UNION ALL
						(SELECT
							name,
							size_bytes,
							price,
							review_count::NUMERIC,
							rating,
							content_rating,
							primary_genre
						FROM app_store_apps))
SELECT
	name,
	content_rating,
	genres,
	AVG(review_count)::INT AS avg_review_count,
	ROUND(AVG(rating),2) AS actual_avg_rating,
	FLOOR(AVG(rating)/.25)*.25 AS rounded_avg_rating,
		(((FLOOR(AVG(rating)/.25)*.25)*2)+1) AS years_viable,
	ROUND((((((FLOOR(AVG(rating)/.25)*.25)*2)+1)*12)*1000),2)::money AS marketing_cost,
	CASE	WHEN price <= 2.5 THEN 25000::money
			ELSE price * 10000::money END AS app_price,
	(((FLOOR(AVG(rating)/.25)*.25)*1000)*12)::money AS rating_value_by_year,
	(ROUND((((((FLOOR(AVG(rating)/.25)*.25)*2)+1)*12)*1000),2)::money)+(CASE	WHEN price <= 2.5 THEN 25000::money
		ELSE price * 10000::money END) AS total_cost,
	((((FLOOR(AVG(rating)/.25)*.25)*1000)*12)::money)*(((FLOOR(AVG(rating)/.25)*.25)*2)+1) AS in_app_sales,
	(((((AVG(rating))*2)+1)*12)*((FLOOR(AVG(rating)/.25)*.25)*1000)::money)-								 	((ROUND((((((FLOOR(AVG(rating)/.25)*.25)*2)+1)*12)*1000),2)::money)+
	(CASE	WHEN price <= 2.5 THEN 25000::money ELSE price * 10000::money END)) AS total_earnings
FROM unioned_table
WHERE rating IS NOT NULL
GROUP BY name, content_rating, genres, price
ORDER BY total_earnings DESC, avg_review_count DESC;

SELECT name, AVG(review_count), AVG(rating) AS actual_avg_rating, AVG(FLOOR(rating/.25)*.25) AS rounded_avg_rating, FLOOR(AVG(rating)/.25)*.25
FROM play_store_apps
WHERE name LIKE ('PewDiePie%')
GROUP BY name, rating;


SELECT name, price, rating, ROUND(rating*1000) AS monthly_earning
,CASE
    WHEN price::money::NUMERIC*10000<=25000 THEN 25000
	ELSE price::money::NUMERIC*10000
	END AS purchase_price, FLOOR(AVG(rating/0.25)*0.25) AS rounded_rating,
	CASE WHEN FLOOR(AVG(rating/0.25)*0.25)=0 THEN 12
         WHEN FLOOR(AVG(rating/0.25)*0.25) =1 THEN 36
	     WHEN FLOOR(AVG(rating/0.25)*0.25) =2 THEN 60
	     WHEN FLOOR(AVG(rating/0.25)*0.25) =3 THEN 84
	     WHEN FLOOR(AVG(rating/0.25)*0.25) =4 THEN 108
	 ELSE 0
	 END AS expected_lifespan
FROM app_store_apps
where name = 'Bible'
GROUP BY name, price,rating
union all
SELECT name, price::money::numeric, rating, ROUND(rating*1000) AS monthly_earning
,CASE
    WHEN price::money::NUMERIC*10000<=25000 THEN 25000
	ELSE price::money::NUMERIC*10000
	END AS purchase_price, FLOOR(AVG(rating/0.25)*0.25) AS rounded_rating,
	CASE WHEN FLOOR(AVG(rating/0.25)*0.25)=0 THEN 12
         WHEN FLOOR(AVG(rating/0.25)*0.25) =1 THEN 36
	     WHEN FLOOR(AVG(rating/0.25)*0.25) =2 THEN 60
	     WHEN FLOOR(AVG(rating/0.25)*0.25) =3 THEN 84
	     WHEN FLOOR(AVG(rating/0.25)*0.25) =4 THEN 108
	 ELSE 0
	 END AS expected_lifespan
FROM play_store_apps
where name = 'Bible'
GROUP BY name,price,rating;