--DROP FUNCTION recommend_content_by_genre(integer, integer);

CREATE OR REPLACE FUNCTION recommend_content_by_genre(user_id_input INTEGER, top_genres_count INTEGER DEFAULT 3)
RETURNS TABLE (
    recommended_content_id INTEGER,
    title VARCHAR,
    genre_names VARCHAR,  -- Changed column name to show all genres
    rating DECIMAL(3, 1)
) AS $$
BEGIN
    RETURN QUERY
    WITH user_genre_preference AS (
        SELECT 
            g.genre_id,
            g.genre_name,
            COUNT(*) AS genre_count
        FROM 
            view_history vh
        INNER JOIN content c ON vh.content_id = c.content_id
        INNER JOIN content_genre cg ON c.content_id = cg.content_id
        INNER JOIN genre g ON cg.genre_id = g.genre_id
        WHERE 
            vh.user_id = user_id_input
        GROUP BY 
            g.genre_id, g.genre_name
        ORDER BY 
            genre_count DESC, MAX(vh.view_time) DESC -- Most frequent and recent genres
        LIMIT top_genres_count -- Select top N genres
    )
    SELECT 
        c.content_id AS recommended_content_id,
        c.title,
        STRING_AGG(g.genre_name, ', ')::VARCHAR AS genre_names, -- Concatenate all genre names
        c.rating
    FROM 
        content c
    INNER JOIN content_genre cg ON c.content_id = cg.content_id
    INNER JOIN genre g ON cg.genre_id = g.genre_id
    WHERE 
        g.genre_id IN (SELECT genre_id FROM user_genre_preference) -- Match one of the top genres
        AND c.content_id NOT IN (
            SELECT vh.content_id FROM view_history vh WHERE vh.user_id = user_id_input
        ) -- Exclude already watched content
    GROUP BY 
        c.content_id, c.title, c.rating -- Group by content to avoid duplicates
    ORDER BY 
        c.rating DESC, -- Highest-rated content first
        c.release_date DESC -- Newer content prioritized
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

/*CREATE OR REPLACE FUNCTION recommend_content_by_genre(user_id_input INTEGER, top_genres_count INTEGER DEFAULT 3)
RETURNS TABLE (
    recommended_content_id INTEGER,
    title VARCHAR,
    genre_name VARCHAR,
    rating DECIMAL(3, 1)
) AS $$
BEGIN
    RETURN QUERY
    WITH user_genre_preference AS (
        SELECT 
            g.genre_id,
            g.genre_name,
            COUNT(*) AS genre_count
        FROM 
            view_history vh
        INNER JOIN content c ON vh.content_id = c.content_id
        INNER JOIN content_genre cg ON c.content_id = cg.content_id
        INNER JOIN genre g ON cg.genre_id = g.genre_id
        WHERE 
            vh.user_id = user_id_input
        GROUP BY 
            g.genre_id, g.genre_name
        ORDER BY 
            genre_count DESC, MAX(vh.view_time) DESC -- Most frequent and recent genres
        LIMIT top_genres_count -- Select top N genres
    )
    SELECT 
        c.content_id AS recommended_content_id,
        c.title,
        g.genre_name,
        c.rating
    FROM 
        content c
    INNER JOIN content_genre cg ON c.content_id = cg.content_id
    INNER JOIN genre g ON cg.genre_id = g.genre_id
    WHERE 
        g.genre_id IN (SELECT genre_id FROM user_genre_preference) -- Match one of the top genres
        AND c.content_id NOT IN (
            SELECT vh.content_id FROM view_history vh WHERE vh.user_id = user_id_input
        ) -- Exclude already watched content
    ORDER BY 
        c.rating DESC, -- Highest-rated content first
        c.release_date DESC -- Newer content prioritized
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;
*/

select * 
from recommend_content_by_genre(680, 3);