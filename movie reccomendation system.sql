USE imdb;
SELECT table_name, table_rows FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'imdb';
SELECT Sum(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS ID,Sum(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS title,Sum(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS year,Sum(CASE WHEN date_published IS NULL THEN 1 ELSE 0 END) AS date_published,Sum(CASE WHEN duration IS NULL THEN 1 ELSE 0 END) AS duration,Sum(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country,Sum(CASE WHEN worlwide_gross_income IS NULL THEN 1 ELSE 0 END) AS worlwide_gross_income,Sum(CASE WHEN languages IS NULL THEN 1 ELSE 0 END) AS languages,Sum(CASE WHEN production_company IS NULL THEN 1 ELSE 0 END) AS production_company FROM   movie; 
SELECT year, COUNT(*) AS number_of_movies FROM movie GROUP BY year ORDER BY year;
SELECT COUNT(id) AS num_of_movies FROM movie WHERE(country LIKE '%USA%'OR country LIKE '%India%')AND year = 2019;
SELECT DISTINCT genre FROM genre;
SELECT genre,COUNT(*) AS num_of_movie_produced_overall FROM genre GROUP BY genre order by num_of_movie_produced_overall desc LIMIT 1;
WITH one_genre AS (SELECT movie_id,COUNT(genre) AS genre FROM genre GROUP BY movie_id HAVING genre = 1)SELECT COUNT(movie_id) AS only_one_genre FROM one_genre;
SELECT g.genre,ROUND(AVG(m.duration), 0) AS avg_duration FROM genre AS g INNER JOIN movie AS m ON g.movie_id = m.id GROUP BY g.genre ORDER BY 1 DESC;
SELECT genre,COUNT(*) AS movie_count,RANK() OVER (ORDER BY COUNT(*) DESC) AS genre_rank FROM genre GROUP BY genre;

SELECT
   MIN(avg_rating) AS min_avg_rating,
   MAX(avg_rating) AS max_avg_rating,
   MIN(total_votes) AS min_total_votes,
   MAX(total_votes) AS max_total_votes,
   MIN(median_rating) AS min_median_rating,
   MAX(median_rating) AS max_median_rating 
FROM ratings;
SELECT title,avg_rating,RANK() OVER(ORDER BY avg_rating DESC ) movie_rank FROM ratings a JOIN movie b on a.movie_id = b.id ORDER BY 3 LIMIT 10;
SELECT median_rating,count(movie_id) AS movie_count FROM ratings GROUP BY median_rating ORDER BY 1;
SELECT m.production_company,count(m.id) AS movie_count,RANK() OVER(ORDER BY count(m.id) DESC) prod_company_rank FROM ratings r INNER JOIN movie m ON r.movie_id = m.id WHERE r.avg_rating > 8 GROUP BY m.production_company LIMIT 5;
SELECT genre,COUNT(g.movie_id) AS movie_count FROM genre AS g INNER JOIN movie AS m ON g.movie_id = m.id INNER JOIN ratings AS r ON m.id = r.movie_id WHERE year = 2017 AND MONTH(date_published) = 3 AND LOWER(country) LIKE '%USA%' AND total_votes > 1000 GROUP BY genre ORDER BY movie_count DESC;
SELECT DISTINCT title,avg_rating, genre FROM movie AS m INNER JOIN genre AS g ON m.id =g.movie_id INNER JOIN ratings AS r ON m.id = r.movie_id WHERE title like 'The%' AND avg_rating>8 ORDER BY genre, avg_rating DESC;
SELECT count(m.id) AS movie_ct FROM movie AS m INNER JOIN ratings AS r ON m.id = r.movie_id WHERE median_rating = 8 AND date_published BETWEEN '2018-04-01' AND '2019-04-01';
SELECT sum(total_votes) FROM movie m JOIN ratings r ON m.id = r.movie_id WHERE country LIKE '%Germany%' ;
SELECT sum(total_votes) FROM movie m JOIN ratings r ON m.id = r.movie_id WHERE country LIKE '%Italy%';
SELECT COUNT(CASE WHEN name IS NULL THEN id END) AS name_nulls, COUNT(CASE WHEN height IS NULL THEN id END) AS height_nulls, COUNT(CASE WHEN date_of_birth IS NULL THEN id END) AS date_of_birth_nulls, COUNT(CASE WHEN known_for_movies IS NULL THEN id END) AS known_for_movies_nulls FROM names;
WITH top_rated_genres AS (SELECT genre,COUNT(m.id) AS movie_count,RANK () OVER (ORDER BY COUNT(m.id) DESC) AS genre_rank FROM genre AS g LEFT JOIN movie AS m ON g.movie_id = m.id INNER JOIN ratings AS r ON m.id = r.movie_id WHERE avg_rating > 8 GROUP BY genre) SELECT n.name as director_name,COUNT(m.id) AS movie_count FROM names AS n INNER JOIN director_mapping AS d ON n.id = d.name_id INNER JOIN movie AS m ON d.movie_id = m.id INNER JOIN ratings AS r ON m.id = r.movie_id INNER JOIN genre AS g ON g.movie_id = m.id WHERE g.genre IN (SELECT DISTINCTgenre FROM top_rated_genres WHERE genre_rank <= 3)AND avg_rating > 8 GROUP BY name ORDER BY movie_count DESC LIMIT 3;

SELECT n.name as actor_name,COUNT(m.id) AS movie_count FROM names AS n INNER JOIN role_mapping AS a ON n.id = a.name_id INNER JOIN movie AS m ON a.movie_id = m.id INNER JOIN ratings AS r ON m.id = r.movie_id WHERE median_rating >= 8 AND category = 'actor' GROUP BY actor_name ORDER BY movie_count DESC LIMIT 2;

SELECT m.production_company, sum(r.total_votes) vote_count, RANK() OVER (ORDER BY sum(r.total_votes) DESC) prod_comp_rank FROM movie m JOIN ratings r on m.id = r.movie_id GROUP BY m.production_company ORDER BY 3 LIMIT 3;

WITH Indian AS (SELECT n.name AS actor_name,r.total_votes,m.id, r.avg_rating,total_votes * avg_rating AS w_avg FROM names n INNER JOIN role_mapping ro ON n.id = ro.name_id INNER JOIN ratings r ON ro.movie_id = r.movie_id INNER JOIN movie m ON m.id = r.movie_id WHERE category = 'Actor'AND country = 'India' ORDER BY actor_name),Actor AS(SELECT*,SUM(w_avg) OVER w1 AS rating,SUM(total_votes) OVER w2 AS Votes FROM Indian WINDOW w1 AS(PARTITION BY actor_name),w2 AS (PARTITION BY actor_name)) SELECT actor_name,Votes AS total_votes,COUNT(id) AS movie_count,ROUND(rating / Votes, 2) AS actor_avg_rating,DENSE_RANK () OVER (ORDER BY rating / Votes DESC) AS actor_rank FROM Actor GROUP BY actor_name HAVING movie_count >= 5;

WITH Indian AS(SELECT n.name AS actress_name,r.total_votes,m.id,r.avg_rating,total_votes * avg_rating AS w_avg FROM names n INNER JOIN role_mapping ro ON n.id = ro.name_id INNER JOIN ratings r ON ro.movie_id = r.movie_id INNER JOIN movie m ON m.id = r.movie_id WHERE category = 'Actress' AND languages = 'Hindi' ORDER BY actress_name),Actress AS(SELECT*,SUM(w_avg) OVER w1 AS rating,SUM(total_votes) OVER w2 AS Votes FROM Indian WINDOW w1 AS(PARTITION BY actress_name),w2 AS(PARTITION BY actress_name))SELECT actress_name,Votes AS total_votes,COUNT(id) AS movie_count,ROUND(rating / Votes, 2) AS actress_avg_rating,DENSE_RANK () OVER (ORDER BY rating / Votes DESC) AS actress_rank FROM Actress GROUP BY actress_name HAVING movie_count >= 3;

SELECT m.title,r.avg_rating,CASE WHEN avg_rating > 8 THEN'Superhit' WHEN avg_rating BETWEEN 7 AND 8 THEN'Hit'WHEN avg_rating BETWEEN 5 AND 7 THEN'One-time-watch' ELSE'Flop movies' END AS movie_type FROM movie m INNER JOIN ratings r ON m.id = r.movie_id INNER JOIN genre g ON m.id = g.movie_id WHERE genre = 'thriller';

WITH genre_summary AS(SELECT genre,ROUND(AVG(duration), 2) AS avg_duration FROM genre AS g LEFT JOIN movie AS m ON g.movie_id = m.id GROUP BY genre)SELECT*,SUM(avg_duration) OVER (ORDER BY genre ROWS UNBOUNDED PRECEDING) AS running_total_duration,AVG(avg_duration) OVER (ORDER BY genre ROWS UNBOUNDED PRECEDING) AS moving_avg_duration FROM genre_summary;

SELECT genre,COUNT(movie_id) AS movie_count FROM genre GROUP BY genre ORDER BY movie_count DESC LIMIT 3;

WITH top_genres AS(SELECT genre,COUNT(m.id) AS movie_count,RANK () OVER (ORDER BY COUNT(m.id) DESC) AS genre_rank FROM genre AS g LEFT JOIN movie AS m ON g.movie_id = m.id GROUP BY genre),top_grossing AS(SELECT g.genre,year,m.title as movie_name,worlwide_gross_income,RANK() OVER (PARTITION BY g.genre, year ORDER BY CONVERT(REPLACE(TRIM(worlwide_gross_income), "$ ",""), UNSIGNED INT) DESC) AS movie_rank FROM movie AS m INNER JOIN genre AS g ON g.movie_id = m.id WHERE g.genre IN (SELECT DISTINCT genre FROM top_genres WHERE genre_rank<=3))SELECT * FROM top_grossing WHERE movie_rank<=5;

WITH production_company_summary AS (SELECT production_company,Count(*) AS movie_count FROM   movie AS m inner join ratings AS r ON r.movie_id = m.id WHERE  median_rating >= 8 AND production_company IS NOT NULL AND Position(',' IN languages) > 0 GROUP  BY production_company ORDER  BY movie_count DESC)SELECT *,Rank()over(ORDER BY movie_count DESC) AS prod_comp_rank FROM   production_company_summary LIMIT 2; 

WITH actress_ratings AS(SELECT n.name as actress_name, SUM(r.total_votes) AS total_votes,COUNT(m.id) as movie_count,ROUND( SUM(r.avg_rating*r.total_votes) / SUM(r.total_votes) , 2) AS actress_avg_rating FROM names AS n INNER JOIN role_mapping AS a ON n.id = a.name_id INNER JOIN movie AS m ON a.movie_id = m.id INNER JOIN ratings AS r ON m.id = r.movie_id INNER JOIN genre AS g ON m.id = g.movie_id WHERE category = 'actress' AND lower(g.genre) = 'drama' GROUP BY actress_name)SELECT*,ROW_NUMBER() OVER (ORDER BY actress_avg_rating DESC, total_votes DESC) AS actress_rank FROM actress_ratings LIMIT 3;SELECT n.name as actress_name,SUM(r.total_votes) AS total_votes,COUNT(m.id) as movie_count,ROUND( SUM(r.avg_rating*r.total_votes) / SUM(r.total_votes) , 2) AS actress_avg_rating FROM names AS n INNER JOIN role_mapping AS a ON n.id = a.name_id INNER JOIN movie AS m ON a.movie_id = m.id INNER JOIN ratings AS r ON m.id = r.movie_id INNER JOIN genre AS g ON m.id = g.movie_id WHERE category = 'actress' AND lower(g.genre) = 'drama' GROUP BY actress_name;
 
WITH top_directors AS(SELECT n.id as director_id,n.name as director_name,COUNT(m.id) AS movie_count,RANK() OVER (ORDER BY COUNT(m.id) DESC) AS director_rank FROM names AS n INNER JOIN director_mapping AS d ON n.id = d.name_id INNER JOIN movie AS m ON d.movie_id = m.id GROUP BY n.id),movie_summary AS(SELECT n.id as director_id,n.name as director_name,m.id AS movie_id,m.date_published,r.avg_rating,r.total_votes,m.duration,LEAD(date_published) OVER (PARTITION BY n.id ORDER BY m.date_published) AS next_date_published,DATEDIFF(LEAD(date_published) OVER (PARTITION BY n.id ORDER BY m.date_published), date_published) AS inter_movie_days FROM names AS n INNER JOIN director_mapping AS d ON n.id = d.name_id INNER JOIN movie AS m ON d.movie_id = m.id INNER JOIN ratings AS r ON m.id = r.movie_id WHERE n.id IN (SELECT director_id FROM top_directors WHERE director_rank <= 9))SELECT director_id,director_name,COUNT(DISTINCT movie_id) AS number_of_movies,ROUND(AVG(inter_movie_days), 0) AS avg_inter_movie_days,ROUND( SUM(avg_rating*total_votes) / SUM(total_votes) , 2) AS avg_rating,SUM(total_votes) AS total_votes,MIN(avg_rating) AS min_rating,MAX(avg_rating) AS max_rating,SUM(duration) AS total_duration FROM movie_summary GROUP BY director_id ORDER BY number_of_movies DESC,avg_rating DESC;





