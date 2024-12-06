--DROP FUNCTION recommend_content_by_location(integer);

CREATE OR REPLACE FUNCTION recommend_content_by_location(user_id_input INTEGER)
RETURNS TABLE (
    recommended_content_id INTEGER,
    title VARCHAR,
    genre_names VARCHAR, -- Aggregated genres
    rating DECIMAL(3, 1)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.content_id AS recommended_content_id,
        c.title,
        STRING_AGG(DISTINCT g.genre_name, ', ')::VARCHAR AS genre_names, -- Cast to VARCHAR
        c.rating
    FROM 
        view_history vh
    INNER JOIN content c ON vh.content_id = c.content_id
    INNER JOIN content_genre cg ON c.content_id = cg.content_id
    INNER JOIN genre g ON cg.genre_id = g.genre_id
    INNER JOIN users u ON vh.user_id = u.user_id
    WHERE 
        vh.view_time >= NOW() - INTERVAL '30 days' -- Recent views
        AND u.country_id = (SELECT country_id FROM users WHERE user_id = user_id_input) -- Same location
    GROUP BY c.content_id, c.title, c.rating
    ORDER BY COUNT(vh.content_id) DESC, -- Most viewed content
             c.rating DESC -- Highest rated
    LIMIT 10;  -- Limit the results to 10
END;
$$ LANGUAGE plpgsql;

SELECT * 
FROM recommend_content_by_location(681);