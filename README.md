# CafeSalesClean

This dataset can be found on Kaggle: https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training

This dataset was intentionally created with a lot of missing values and errors to help practice data cleaning techniques. Firstly, the names of most columns were changed to use underscores instead of spaces, making selecting columns a lot easier. Then all values that were either empty, 'UNKNOWN' or 'ERROR' were changed to NULL to facilitate the data cleaning process

**Transaction_ID:** The Transaction_ID column was not edited or changed since every row had a distinct value indicating that the data in this column was clean and valid.

**Item:** The Item column was first updated according to its Price_Per_Unit column, matching each item with its appropriate price. This method worked for prices associated to 1 item (cookie, tea, coffee and salad), but for prices associated to 2 items (cake, juice, smoothie and sandwich) a different approach was used. For such items and prices, the percentage distribution of each item with the same Price_Per_Unit was calculated. That percentage was then multiplied to the number of NULL values with the associated Price_Per_Unit to determine how many of those NULL values would be assigned the associated item. For example, since cake and juice both cost $3, the percentage of orders where the Price_Per_Unit was 3 was calculated to see what percentage was cake and what percentage was juice. That percentage was then multiplied by the number of NULL values with Price_Per_Unit = 3 to determine how many of those would be assigned cake and how many would be assigned juice.

**Quantity:** The Quantity column was calculated by dividing Total_Spent by Price_Per_Unit.

**Price_Per_Unit:** The Price_Per_Unit column was first updated according to the item, matching each price to its appropriate item. When the item cell was NULL, Price_Per_Unit was calculated by dividing Total_Spent by Quantity, assuming those values were also not NULL.

**Total_Spent:** The Total_Spent column was calculated using by multiplying Quantity by Price_Per_Unit.

**Payment_Method:** The Payment_Method column was populated using the same method as the secondary method described in the items section, where payment_method is assigned in a way to maintain the initial distribution of payment_method.

**Location:** The Location column was populated using the same method as Payment_Method, ensuring the initial distribution remained the same.

**Transaction_Date:** The Transaction_Date column was filled using the backwards fill method according to the Transaction_ID column.

After the data was populated using these techniques, the remaining columns containing multiple NULL values were deleted.
