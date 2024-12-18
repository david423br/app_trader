WITH basic_attributes AS (SELECT name, ROUND((a.rating + p.rating)/2, 2) AS avg_rating,
						     ROUND((a.price + p.price::money::numeric)/2, 2) AS price	  
						FROM app_store_apps AS a INNER JOIN play_store_apps AS p USING (name)),
						
	atts_w_longevity AS (SELECT *, FLOOR(avg_rating/.25) * 6 + 12 AS longevity_in_months
						FROM basic_attributes),
					
	revenue_and_cost AS(SELECT *,
						(FLOOR(avg_rating/.25) * .25) * 1000 * longevity_in_months * 2 AS lifelong_revenue,
						 longevity_in_months * 1000 AS lifelong_ad_costs,
					 CASE WHEN price > 2.5 THEN price * 10000
		  			    ELSE 25000 END AS initial_purchase_cost
					FROM atts_w_longevity)
					
SELECT DISTINCT name, lifelong_revenue - lifelong_ad_costs - initial_purchase_cost AS profit
FROM revenue_and_cost
ORDER BY profit DESC
LIMIT 10;


							 
SELECT DISTINCT name, CASE WHEN ROUND((a.price + p.price::money::numeric)/2, 2) > 2.5 THEN (FLOOR(ROUND((a.rating + p.rating)/2, 2)/.25) * .25 * 1000 * 											(FLOOR(ROUND((a.rating + p.rating)/2, 2)/.25) * 6 + 12) * 2) - ((FLOOR(ROUND((a.rating + p.rating)/2, 2)/.25) * 6 + 12) * 1000) - 									(ROUND((a.price + p.price::money::numeric)/2, 2) * 10000) 
						   ELSE (FLOOR(ROUND((a.rating + p.rating)/2, 2)/.25) * .25 * 1000 * (FLOOR(ROUND((a.rating + p.rating)/2, 2)/.25) * 6 + 12) * 2) - 										(FLOOR(ROUND((a.rating + p.rating)/2, 2)/.25) * 6 + 12) * 1000 - (25000) END AS profit
FROM app_store_apps AS a INNER JOIN play_store_apps AS p USING (name)
ORDER BY profit DESC
LIMIT 10;							 




