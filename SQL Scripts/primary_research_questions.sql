/*
1. List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold.
*/

-- Top 3 Makers
SELECT TOP 3
    m.maker AS Maker,
    SUM(m.electric_vehicles_sold) AS EV_Sold
FROM electric_vehicle_sales_by_makers m
INNER JOIN dim_date d ON m.date = d.date
WHERE d.fiscal_year IN (2023, 2024)
    AND m.vehicle_category = '2-Wheelers'
GROUP BY m.maker
ORDER BY SUM(m.electric_vehicles_sold) DESC;


--Bottom 3 Makers
SELECT TOP 3
    m.maker AS Maker,
    SUM(m.electric_vehicles_sold) AS EV_Sold
FROM electric_vehicle_sales_by_makers m
INNER JOIN dim_date d ON m.date = d.date
WHERE d.fiscal_year IN (2023, 2024)
    AND m.vehicle_category = '2-Wheelers'
GROUP BY m.maker
ORDER BY SUM(m.electric_vehicles_sold) ASC;


/*
2. Identify the top 5 states with the highest penetration rate in 2-wheeler 
and 4-wheeler EV sales in FY 2024.
*/

-- For 2-Wheelers
SELECT TOP 5
    s.state,
    ROUND(SUM(s.electric_vehicles_sold)/CAST(SUM(s.total_vehicles_sold) AS float) * 100, 2) Penetration_Rate
FROM electric_vehicle_sales_by_state s
INNER JOIN dim_date d ON s.date = d.date
WHERE s.vehicle_category = '2-Wheelers'
    AND d.fiscal_year = 2024
GROUP BY s.state
ORDER BY Penetration_Rate DESC;

-- For 4-Wheelers
SELECT TOP 5
    s.state,
    ROUND(SUM(s.electric_vehicles_sold)/CAST(SUM(s.total_vehicles_sold) AS float) * 100, 2) Penetration_Rate
FROM electric_vehicle_sales_by_state s
INNER JOIN dim_date d ON s.date = d.date
WHERE s.vehicle_category = '4-Wheelers'
    AND d.fiscal_year = 2024
GROUP BY s.state
ORDER BY Penetration_Rate DESC;


/*
3. List the states with negative penetration (decline) in EV sales from 2022 to 2024?
*/

WITH penetration_22 AS (
    SELECT
        s.state,
        ROUND(SUM(s.electric_vehicles_sold)/CAST(SUM(s.total_vehicles_sold) AS float) * 100, 2) Penetration_Rate
    FROM electric_vehicle_sales_by_state s
    INNER JOIN dim_date d ON s.date = d.date
    WHERE d.fiscal_year = 2022
    GROUP BY s.state
),

penetration_24 AS (
    SELECT
        s.state,
        ROUND(SUM(s.electric_vehicles_sold)/CAST(SUM(s.total_vehicles_sold) AS float) * 100, 2) Penetration_Rate
    FROM electric_vehicle_sales_by_state s
    INNER JOIN dim_date d ON s.date = d.date
    WHERE d.fiscal_year = 2024
    GROUP BY s.state
)

SELECT
    p22.state AS State,
    p22.Penetration_Rate AS Penetration_2022,
    p24.Penetration_Rate AS Penetration_2024,
    CASE
        WHEN p24.Penetration_Rate < p22.Penetration_Rate
        THEN 'Decline'
        ELSE 'Postive Penetration'
    END AS Penetration_Status
FROM penetration_22 p22
INNER JOIN penetration_24 p24 ON p22.state = p24.state;


/*
4. What are the quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?
*/


WITH top_5_makers_by_ev_sales AS (
    SELECT TOP 5
        e.maker,
        SUM(e.electric_vehicles_sold) AS ev_sold
    FROM electric_vehicle_sales_by_makers e
    JOIN dim_date d ON e.date = d.date
    WHERE d.fiscal_year BETWEEN 2022 AND 2024
        AND e.vehicle_category = '4-Wheelers'
    GROUP BY e.maker
    ORDER BY ev_sold DESC
    
)

SELECT
    e.maker AS Maker,
    d.quarter AS Quarter,
    SUM(e.electric_vehicles_sold) AS EV_Sold
FROM top_5_makers_by_ev_sales T5
JOIN electric_vehicle_sales_by_makers e ON T5.maker = e.maker
JOIN dim_date d ON d.date = e.date
WHERE d.fiscal_year BETWEEN 2022 AND 2024
GROUP BY e.maker, d.quarter
ORDER BY e.maker, d.quarter;



/*
5. How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024?
*/

SELECT
    s.state,
    SUM(s.electric_vehicles_sold) AS EV_Sold,
    ROUND(SUM(s.electric_vehicles_sold)/CAST(SUM(s.total_vehicles_sold) AS float) * 100, 2) AS Penetration_Rate
FROM electric_vehicle_sales_by_state s
INNER JOIN dim_date d ON s.date = d.date
WHERE s.state IN ('Delhi', 'Karnataka')
    AND d.fiscal_year = 2024
GROUP BY s.state
ORDER BY Penetration_Rate DESC;


/*
6. List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024.
*/

WITH cagr_calculation AS (
    SELECT
        e.maker,
        ROUND(
            (POWER(
                (COALESCE(SUM(CASE WHEN d.fiscal_year = 2024 THEN e.electric_vehicles_sold ELSE 0 END), 0) 
                / CAST(NULLIF(COALESCE(SUM(CASE WHEN d.fiscal_year = 2022 THEN e.electric_vehicles_sold ELSE 0 END), 0), 0)AS FLOAT)),
                1.0 / 2
            ) - 1) * 100, 2) AS CAGR
    FROM electric_vehicle_sales_by_makers e
    JOIN dim_date d ON e.date = d.date
    WHERE e.vehicle_category = '4-Wheelers'
    GROUP BY e.maker
)

SELECT TOP 5 
	*
FROM cagr_calculation
WHERE CAGR IS NOT NULL
ORDER BY CAGR DESC;


/*
7. List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.
*/

WITH cagr_calculation AS (
    SELECT
        s.state
        ,ROUND(
            (POWER(
                (SUM(CASE WHEN d.fiscal_year = 2024 THEN s.electric_vehicles_sold ELSE 0 END) 
                / CAST(NULLIF(SUM(CASE WHEN d.fiscal_year = 2022 THEN s.electric_vehicles_sold ELSE 0 END), 0) AS FLOAT)),
                1.0 / 2 -- Number of years (2022 to 2024 is 2 years)
            ) - 1) * 100, 2) AS CAGR
    FROM electric_vehicle_sales_by_state s
    JOIN dim_date d ON s.date = d.date
    GROUP BY s.state
)

SELECT TOP 10
	*
FROM cagr_calculation
WHERE CAGR IS NOT NULL
ORDER BY CAGR DESC;


/*
8. What are the peak and low season months for EV sales based on the data from 2022 to 2024?
*/

SELECT
    DISTINCT FORMAT(d.date, 'MMMM') AS month_name,
    SUM(m.electric_vehicles_sold) AS ev_sold
FROM dim_date d
JOIN electric_vehicle_sales_by_makers m ON d.date = m.date
GROUP BY FORMAT(d.date, 'MMMM')
ORDER BY SUM(m.electric_vehicles_sold) DESC;


/*
9. What is the projected number of EV sales (including 2-wheelers and 4-wheelers) for the top 10 states by penetration rate in 2030, 
based on the  compounded annual growth rate (CAGR) from previous years?
*/

WITH cagr_calculation AS (
    SELECT
        s.state
        ,ROUND(
            (POWER(
                (SUM(CASE WHEN d.fiscal_year = 2024 THEN s.electric_vehicles_sold ELSE 0 END) 
                / CAST(NULLIF(SUM(CASE WHEN d.fiscal_year = 2022 THEN s.electric_vehicles_sold ELSE 0 END), 0) AS FLOAT)),
                1.0 / 2
            ) - 1) * 100, 2) AS CAGR
    FROM electric_vehicle_sales_by_state s
    JOIN dim_date d ON s.date = d.date
    GROUP BY s.state
),

cagr_by_state AS (
    SELECT *
    FROM cagr_calculation
    WHERE CAGR IS NOT NULL
),

penetration_rate_by_state AS (
    SELECT
        s.state,
        ROUND(SUM(s.electric_vehicles_sold) / CAST(SUM(s.total_vehicles_sold) AS FLOAT) * 100.0, 2) AS penetration_rate
    FROM electric_vehicle_sales_by_state s
    JOIN dim_date d ON s.date = d.date
    WHERE d.fiscal_year = 2024
        AND s.vehicle_category = '2-Wheelers'
    GROUP BY s.state
),

top_10_states_by_penetration AS (
    SELECT TOP 10
        PRBS.state,
        PRBS.penetration_rate,
        CBS.CAGR
    FROM penetration_rate_by_state PRBS
    JOIN cagr_by_state CBS ON PRBS.state = CBS.state
)

SELECT
    T10.state,
    ROUND(
        SUM(CASE WHEN d.fiscal_year = 2024 THEN s.electric_vehicles_sold ELSE 0 END)
        * POWER(1 + T10.CAGR / 100, 2030 - 2024), 0
    ) AS projected_ev_sales_2030
FROM top_10_states_by_penetration T10
JOIN electric_vehicle_sales_by_state s ON T10.state = s.state
JOIN dim_date d ON s.date = d.date
WHERE d.fiscal_year = 2024
GROUP BY T10.state, T10.CAGR
ORDER BY 2 DESC;


/*
10. Estimate the revenue growth rate of 4-wheeler and 2-wheelers  EVs in India for 2022 vs 2024 and 2023 vs 2024,
assuming an average  unit price for 2-Wheelers (85000) and for 4-wheelers (1500000).
*/

WITH revenue_by_year AS (
    SELECT
        s.vehicle_category,
        d.fiscal_year,
        SUM(CAST(s.electric_vehicles_sold AS BIGINT) * 
            CASE
                WHEN s.vehicle_category = '2-Wheelers' THEN 85000
                WHEN s.vehicle_category = '4-Wheelers' THEN 1500000
                ELSE 0
            END
        ) AS total_revenue
    FROM electric_vehicle_sales_by_state s
    JOIN dim_date d ON s.date = d.date
    WHERE d.fiscal_year IN (2022, 2023, 2024)
    GROUP BY s.vehicle_category, d.fiscal_year
),

revenue_growth AS (
    SELECT
        vehicle_category,
        fiscal_year,
        total_revenue,
        LAG(total_revenue) OVER (PARTITION BY vehicle_category ORDER BY fiscal_year) AS prev_revenue
    FROM revenue_by_year
)

SELECT
    vehicle_category,
    fiscal_year,
    ROUND(((total_revenue - prev_revenue) / NULLIF(CAST(prev_revenue AS FLOAT), 0)) * 100, 2) AS revenue_growth_rate
FROM revenue_growth
WHERE fiscal_year IN (2022, 2023, 2024)
    AND prev_revenue IS NOT NULL
ORDER BY vehicle_category, fiscal_year;