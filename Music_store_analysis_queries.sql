/* Query for creating Tables */

CREATE TABLE employee (
    employee_id VARCHAR(50) PRIMARY KEY,
    last_name CHAR(50),
    first_name CHAR(50),
    title VARCHAR(50),
    reports_to VARCHAR(50),
    levels VARCHAR(10),
    birthdate TIMESTAMP,
    hire_date TIMESTAMP,
    address VARCHAR(120),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(30),
    postal_code VARCHAR(30),
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(30)
);

CREATE TABLE customer (
    customer_id VARCHAR(30) PRIMARY KEY,
    first_name CHAR(30),
    last_name CHAR(30),
    company VARCHAR(100),
    address VARCHAR(120),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(30),
    postal_code VARCHAR(30),
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(30),
    support_rep_id VARCHAR(50)
);

CREATE TABLE invoice (
    invoice_id VARCHAR(30) PRIMARY KEY,
    customer_id VARCHAR(30),
    invoice_date TIMESTAMP,
    billing_address VARCHAR(120),
    billing_city VARCHAR(50),
    billing_state VARCHAR(50),
    billing_country VARCHAR(30),
    billing_postal VARCHAR(30),
    total FLOAT8
);

CREATE TABLE invoice_line (
    invoice_line_id VARCHAR(50) PRIMARY KEY,
    invoice_id VARCHAR(30),
    track_id VARCHAR(50),
    unit_price VARCHAR(30),
    quantity VARCHAR(30)
);

CREATE TABLE track (
    track_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150),
    album_id VARCHAR(30),
    media_type_id VARCHAR(30),
    genre_id VARCHAR(30),
    composer VARCHAR(200),
    milliseconds INT,
    bytes INT8,
    unit_price FLOAT
);

CREATE TABLE playlist (
    playlist_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(30)
);

CREATE TABLE playlist_track (
    playlist_id VARCHAR(50),
    track_id VARCHAR(50),
    PRIMARY KEY (playlist_id, track_id)
);

CREATE TABLE artist (
    artist_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE album (
    album_id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(120),
    artist_id VARCHAR(50)
);

CREATE TABLE media_type (
    media_type_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(30)
);

CREATE TABLE genre (
    genre_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(30)
);

/* Q1. Write a query to fetch any table. */

SELECT * FROM album

/* Q2. Who is the senior most employee based on job title? */

SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

/* Q3. Which countries have the most invoices? */

SELECT COUNT(*) AS invoice_count, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY  invoice_count DESC;

/* Q4. What are the top 3 values of total invoice? */

SELECT invoice_id, total
FROM invoice
ORDER BY total DESC
LIMIT 3;

/* Q5. Which city has the best customers? 
       (We would like to throw a promotional Music Festival in the city we made the most money in.)
	   Write a query that returns one city that has the highest sum of invoice totals.
	   (Return both the city name & sum of all invoice totals.) */
	   
SELECT SUM(total) AS invoice_total, billing_city
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC
LIMIT 1;

/* Q6.  Who is the best customer?(The customer who has spent the most money will be declared the best customer.)
        Write a query that returns the person who has spent the most money. */

SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS invoice_total
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY invoice_total DESC
LIMIT 1;

/* Q7. Write query to return the email, first name, last name, & Genre of all Rock Music listeners.
       Return your list ordered alphabetically by email starting with alphabet A. */
	   
SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

-- OR we can use this alternate method below:

SELECT DISTINCT email AS Email,first_name AS FirstName, last_name AS LastName, genre.name AS genre_name
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email;

/* Q8. (Let's invite the artists who have written the most rock music in our dataset.)
       Write a query that returns the Artist name and total track count of the top 10 rock bands. */
	   
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

/* Q9. Return all the track names that have a song length longer than the average song length.
       Return the Name and Milliseconds for each track.
       (Order by the song length with the longest songs listed first.) */

SELECT name,milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track )
ORDER BY milliseconds DESC;

/* Q10. Find how much amount spent by each customer on artists?
        Write a query to return customer name, artist name and total spent. */
	  
-- We will use CTE(Common Table Expression) for this:

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, 
	SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/* Q11. We want to find out the most popular music Genre for each country.
        We determine the most popular genre as the genre with the highest amount of purchases.
        Write a query that returns each country along with the top Genre.
        For countries where the maximum number of purchases is shared return all Genres. */
		
WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

-- OR we can use an alternate method using Recursive:

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

/* Q12. Write a query that determines the customer that has spent the most on music for each country.
        Write a query that returns the country along with the top customer and how much they spent.
        For countries where the top amount spent is shared, provide all customers who spent this amount. */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1

-- OR we can use an alternate method using Recursive:

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;

/* This concludes our Queries */