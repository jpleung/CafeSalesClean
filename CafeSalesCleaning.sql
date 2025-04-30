-- Use the proper schema
USE Cafe;

-- Rename columns to use _ instead of space
ALTER TABLE cafesales
RENAME COLUMN `Transaction ID` TO Transaction_ID;
ALTER TABLE cafesales
RENAME COLUMN `Price Per Unit` TO Price_Per_Unit;
ALTER TABLE cafesales
RENAME COLUMN `Total Spent` TO Total_Spent;
ALTER TABLE cafesales
RENAME COLUMN `Payment Method` TO Payment_Method;
ALTER TABLE cafesales
RENAME COLUMN `Transaction Date` TO Transaction_Date;

-- Set all empty, UNKNOWN or ERROR cells to NULL
UPDATE cafesales
SET item = NULL 
WHERE item = '' OR item = 'UNKNOWN' OR item = 'ERROR';
UPDATE cafesales
SET quantity = NULL
WHERE quantity = '' OR quantity = 'UNKNOWN' OR item = 'ERROR';
UPDATE cafesales
SET price_per_unit = NULL
WHERE price_per_unit = '' OR price_per_unit = 'UNKNOWN' OR price_per_unit = 'ERROR';
UPDATE cafesales
SET total_spent = NULL
WHERE total_spent = '' OR total_spent = 'UNKNOWN' OR total_spent = 'ERROR';
UPDATE cafesales
SET payment_method = NULL
WHERE payment_method = '' OR payment_method = 'UNKNOWN' OR payment_method = 'ERROR';
UPDATE cafesales
SET location = NULL
WHERE location = '' OR location = 'UNKNOWN' OR location = 'ERROR';
UPDATE cafesales
SET transaction_date = NULL
WHERE transaction_date = '' OR transaction_date = 'UNKNOWN' OR transaction_date = 'ERROR';

-- Fill missing items according to price_per_unit (items priced 1, 1.5, 2 and 5)
UPDATE cafesales
SET item = CASE WHEN price_per_unit = 1 THEN 'Cookie'
				WHEN price_per_unit = 1.5 THEN 'Tea'
                WHEN price_per_unit = 2 THEN 'Coffee'
                WHEN price_per_unit =  5 THEN 'Salad' 
                ELSE item END
WHERE item IS NULL;

-- Fill missing items according to price_per_unit (items priced 3)
-- 1085 Cake, 1110 Juice, 234 NULL
SELECT item, COUNT(*)
FROM cafesales
WHERE price_per_unit = 3
GROUP BY 1;
-- Find how many of each to set to Cake and Juice to keep the same distribution
SELECT item, ROUND((SELECT COUNT(*) FROM cafesales WHERE price_per_unit = 3 AND item IS NULL)*
		(COUNT(*) / (SELECT COUNT(*) FROM cafesales WHERE price_per_unit = 3 AND item IS NOT NULL)))
FROM cafesales
WHERE price_per_unit = 3 AND item IS NOT NULL
GROUP BY 1;
-- Fill values Cake and Juice values
UPDATE cafesales
SET item = 'Cake'
WHERE item IS NULL AND price_per_unit = 3
LIMIT 116;
UPDATE cafesales
SET item = 'Juice'
WHERE item IS NULL AND price_per_unit = 3
LIMIT 118;

-- Fill missing items according to price_per_unit (items priced 4)
-- 1036 Smoothie, 1082 Sandwich, 213 NULL
SELECT item, COUNT(*)
FROM cafesales
WHERE price_per_unit = 4
GROUP BY 1;
-- Find how many of each to set to Smoothie and Sandwich to keep the same distribution
SELECT item, ROUND((SELECT COUNT(*) FROM cafesales WHERE price_per_unit = 4 AND item IS NULL)*
		(COUNT(*) / (SELECT COUNT(*) FROM cafesales WHERE price_per_unit = 4 AND item IS NOT NULL)))
FROM cafesales
WHERE price_per_unit = 4 AND item IS NOT NULL
GROUP BY 1;
-- Fill Smoothie and Sandwich values
UPDATE cafesales
SET item = 'Smoothie'
WHERE item IS NULL AND price_per_unit = 4
LIMIT 104;
UPDATE cafesales
SET item = 'Sandwich'
WHERE item IS NULL AND price_per_unit = 4
LIMIT 109;

-- Fill missing values of price_per_unit
UPDATE cafesales
SET price_per_unit = CASE WHEN item = 'Cookie' THEN 1
						  WHEN item = 'Tea' THEN 1.5
                          WHEN item = 'Coffee' THEN 2
                          WHEN item = 'Cake' THEN 3
                          WHEN item = 'Juice' THEN 3
                          WHEN item = 'Sandwich' THEN 4
                          WHEN item = 'Smoothie' THEN 4
                          WHEN item = 'Salad' THEN 5 
                          ELSE price_per_unit END
WHERE price_per_unit IS NULL AND item IS NOT NULL;

-- Fill empty price_per_unit using to total_spent/quantity when item is NULL (must fill items again after this)
UPDATE cafesales
SET price_per_unit = total_spent / quantity
WHERE price_per_unit IS NULL AND item IS NULL AND quantity IS NOT NULL AND total_spent IS NOT NULL;

-- Fill missing values of quantity with total_spent/price_per_unit
UPDATE cafesales
SET quantity = total_spent / price_per_unit
WHERE quantity IS NULL AND total_spent IS NOT NULL AND price_per_unit IS NOT NULL;

-- Fill missing values of total_spent with quantity * price_per_unit
UPDATE cafesales
SET total_spent = quantity * price_per_unit
WHERE total_spent IS NULL AND quantity IS NOT NULL AND price_per_unit IS NOT NULL; 

-- Fill missing values of payment_method, while keeping the same distribution
SELECT payment_method, COUNT(*)
FROM cafesales
GROUP BY 1;
-- 2273 Credit Card, 2258 Cash, 2291 Digital Wallet, 3178 NULL
SELECT payment_method, ROUND((SELECT COUNT(*) FROM cafesales WHERE payment_method IS NULL)*
		(COUNT(*) / (SELECT COUNT(*) FROM cafesales WHERE payment_method IS NOT NULL)))
FROM cafesales
WHERE payment_method IS NOT NULL
GROUP BY 1;
-- Fill payment_method values
UPDATE cafesales
SET payment_method = 'Credit Card'
WHERE payment_method IS NULL
LIMIT 1059;
UPDATE cafesales
SET payment_method = 'Cash'
WHERE payment_method IS NULL
LIMIT 1052;
UPDATE cafesales
SET payment_method = 'Digital Wallet'
WHERE payment_method IS NULL
LIMIT 1067;

-- Fill missing values of location, while keeping the same distribution
SELECT location, COUNT(*)
FROM cafesales
GROUP BY 1;
-- 3022 Takeaway, 2017 In-store, 3961 NULL
SELECT location, ROUND((SELECT COUNT(*) FROM cafesales WHERE location IS NULL)*
		(COUNT(*) / (SELECT COUNT(*) FROM cafesales WHERE location IS NOT NULL)))
FROM cafesales
WHERE location IS NOT NULL
GROUP BY 1;
-- Fill location values
UPDATE cafesales
SET location = 'Takeaway'
WHERE location IS NULL
LIMIT 1982;
UPDATE cafesales
SET location = 'In-store'
WHERE location IS NULL
LIMIT 1979;

-- Fill transaction_date (backwards fill according to transaction_id)
WITH backwards_date AS (
	SELECT transaction_id, LAG(transaction_date) OVER(ORDER BY transaction_id) AS previous
    FROM cafesales)
UPDATE cafesales cs
JOIN backwards_date bd
ON cs.transaction_id = bd.transaction_id
SET cs.transaction_date = bd.previous
WHERE cs.transaction_date IS NULL;

-- Ensure data is of proper type
ALTER TABLE cafesales
MODIFY COLUMN quantity int;
ALTER TABLE cafesales
MODIFY COLUMN price_per_unit double;
ALTER TABLE cafesales
MODIFY COLUMN total_spent double;
ALTER TABLE cafesales
MODIFY COLUMN transaction_date date;

-- Delete remaining unfilled rows
DELETE FROM cafesales
WHERE item IS NULL OR quantity IS NULL OR price_per_unit IS NULL OR total_spent IS NULL OR payment_method IS NULL
	OR location IS NULL OR transaction_date IS NULL;

-- Create transaction_month column
ALTER TABLE cafesales
ADD COLUMN Transaction_Month text;
UPDATE cafesales
SET transaction_month = CASE WHEN MONTH(transaction_date) = 1 THEN 'January'
							 WHEN MONTH(transaction_date) = 2 THEN 'February'
                             WHEN MONTH(transaction_date) = 3 THEN 'March'
                             WHEN MONTH(transaction_date) = 4 THEN 'April'
                             WHEN MONTH(transaction_date) = 5 THEN 'May'
                             WHEN MONTH(transaction_date) = 6 THEN 'June'
                             WHEN MONTH(transaction_date) = 7 THEN 'July'
                             WHEN MONTH(transaction_date) = 8 THEN 'August'
                             WHEN MONTH(transaction_date) = 9 THEN 'September'
                             WHEN MONTH(transaction_date) = 10 THEN 'October'
                             WHEN MONTH(transaction_date) = 11 THEN 'November'
                             WHEN MONTH(transaction_date) = 12 THEN 'December' END;
                             
-- Create transaction_season column
ALTER TABLE cafesales
ADD COLUMN Transaction_Season text;
UPDATE cafesales
SET transaction_season = CASE WHEN transaction_month IN ('December', 'January', 'February') THEN 'Winter'
							  WHEN transaction_month IN ('March', 'April', 'May') THEN 'Spring'
                              WHEN transaction_month IN ('June', 'July', 'August') THEN 'Summer'
                              WHEN transaction_month IN ('September', 'October', 'November') THEN 'Fall' END;
                              
-- Create transaction_dow column
ALTER TABLE cafesales
ADD COLUMN Transaction_DOW text;
UPDATE cafesales
SET transaction_dow = CASE WHEN DAYOFWEEK(transaction_date) = 1 THEN 'Sunday'
						   WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
                           WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
                           WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
                           WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
                           WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
                           WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday' END;

/* Add category column with 3 categories:
Caffeinated Drink: Coffee, Tea
Non-Caffeinated Drink: Juice, Smoothie
Sweet Snack: Cookie, Cake
Snack: Sandwich, Salad */
ALTER TABLE cafesales
ADD COLUMN Category text;
UPDATE cafesales
SET category = CASE WHEN item = 'Coffee' THEN 'Caffeinated Drink'
					WHEN item = 'Cookie' THEN 'Sweet Snack'
                    WHEN item = 'Tea' THEN 'Caffeinated Drink'
                    WHEN item = 'Cake' THEN 'Sweet Snack'
                    WHEN item = 'Juice' THEN 'Non-Caffeinated Drink'
                    WHEN item = 'Sandwich' THEN 'Snack'
                    WHEN item = 'Smoothie' THEN 'Non-Caffeinated Drink'
                    WHEN item = 'Salad' THEN 'Snack' END;
