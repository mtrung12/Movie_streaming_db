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
        STRING_AGG(g2.genre_name, ', ')::VARCHAR AS genre_names, -- Concatenate all genre names
        c.rating
    FROM 
        content c
    INNER JOIN content_genre cg ON c.content_id = cg.content_id
    LEFT JOIN genre g1 ON cg.genre_id = g1.genre_id -- First join for matching user preferred genres
    LEFT JOIN genre g2 ON cg.genre_id = g2.genre_id -- Second join to gather all genres for content
    WHERE 
        g1.genre_id IN (SELECT genre_id FROM user_genre_preference) -- Match one of the top genres
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

CREATE OR REPLACE FUNCTION subscribe_to_pack(
    NEW_USER_ID INT, 
    NEW_PACK_ID INT
) 
RETURNS VOID AS $$
DECLARE
    pack_duration duration_enum;
    default_pack_id INT := 1;
    current_pack_id INT;
BEGIN
    -- 1. Check if user is already subscribed to the default pack, if so, raise an exception
    SELECT pack_id INTO current_pack_id
    FROM subscription
    WHERE user_id = NEW_USER_ID
      AND end_time = 'infinity'::TIMESTAMP;
    
    IF current_pack_id = default_pack_id AND NEW_PACK_ID = default_pack_id THEN
        RAISE EXCEPTION 'User is already on the default subscription pack.';
    END IF;

    -- 2. Update the current subscription's end_time to NOW() (if the user has an active subscription)
    UPDATE subscription
    SET end_time = CURRENT_TIMESTAMP	
    WHERE user_id = NEW_USER_ID 
      AND end_time > CURRENT_TIMESTAMP;
    
    -- 3. Retrieve the duration of the new subscription pack
    SELECT duration INTO pack_duration
    FROM subscription_pack
    WHERE pack_id = NEW_PACK_ID;

    -- 4. Insert the new subscription with the appropriate end_time
    INSERT INTO subscription (user_id, pack_id, start_time, end_time)
    VALUES (
        NEW_USER_ID,
        NEW_PACK_ID,
        CURRENT_TIMESTAMP,
        CASE 
            WHEN pack_duration = '6' THEN CURRENT_TIMESTAMP + INTERVAL '6 months'
            WHEN pack_duration = '12' THEN CURRENT_TIMESTAMP + INTERVAL '12 months'
            WHEN pack_duration = 'infinity' THEN 'infinity'::TIMESTAMP
        END
    );

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION unsubscribe(NEW_USER_ID INT)
RETURNS VOID AS $$
DECLARE
    default_pack_id INT := 1;
    current_pack_id INT;
BEGIN
    -- 1. Check if user is already on the default pack (pack_id = 1), if so, raise an exception
    SELECT pack_id INTO current_pack_id
    FROM subscription
    WHERE user_id = NEW_USER_ID
      AND end_time = 'infinity'::TIMESTAMP;
    
    IF current_pack_id = default_pack_id THEN
        RAISE EXCEPTION 'User is already on the default subscription pack and cannot unsubscribe from it.';
    END IF;

    -- 2. Update the current subscription's end_time to NOW() (if the user has an active subscription)
    UPDATE subscription
    SET end_time = CURRENT_TIMESTAMP
    WHERE user_id = NEW_USER_ID
      AND end_time > CURRENT_TIMESTAMP;
    
    -- 3. Insert a new subscription for the default pack (pack_id = 1, end_time = 'infinity')
    INSERT INTO subscription (user_id, pack_id, start_time, end_time)
    VALUES (NEW_USER_ID, default_pack_id, CURRENT_TIMESTAMP, 'infinity'::TIMESTAMP);

END;
$$ LANGUAGE plpgsql;


/*CREATE OR REPLACE FUNCTION recommend_content_by_similarity(user_id_input INTEGER)
RETURNS TABLE (
    recommended_content_id INTEGER,
    title VARCHAR,
    genre_name VARCHAR,
    rating DECIMAL(3, 1)
) AS $$
BEGIN
    RETURN QUERY
    WITH user_similarity AS (
        -- Calculate Pearson correlation between target user and other users
        SELECT 
            r1.user_id AS similar_user_id,
            SUM((r1.rating - avg_r1.avg_rating) * (r2.rating - avg_r2.avg_rating)) /
            (SQRT(SUM(POWER(r1.rating - avg_r1.avg_rating, 2))) * SQRT(SUM(POWER(r2.rating - avg_r2.avg_rating, 2)))) AS similarity_score
        FROM 
            rate r1
        INNER JOIN rate r2 ON r1.content_id = r2.content_id AND r1.user_id <> r2.user_id
        CROSS JOIN (
            SELECT user_id, AVG(rating) AS avg_rating FROM rate GROUP BY user_id
        ) avg_r1
        CROSS JOIN (
            SELECT user_id, AVG(rating) AS avg_rating FROM rate GROUP BY user_id
        ) avg_r2
        WHERE 
            r1.user_id = user_id_input AND avg_r1.user_id = r1.user_id AND avg_r2.user_id = r2.user_id
        GROUP BY r1.user_id, r2.user_id
        ORDER BY similarity_score DESC
        LIMIT 5 -- Limit to top 5 similar users
    ),
    similar_users_content AS (
        -- Get content rated highly by similar users
        SELECT 
            r.content_id,
            AVG(r.rating) AS avg_rating
        FROM 
            rate r
        INNER JOIN user_similarity us ON r.user_id = us.similar_user_id
        WHERE 
            r.rating >= 4 -- Only consider highly rated content
        GROUP BY r.content_id
        ORDER BY avg_rating DESC
    )
    SELECT 
        c.content_id AS recommended_content_id,
        c.title,
        g.genre_name,
        c.rating
    FROM 
        similar_users_content suc
    INNER JOIN content c ON suc.content_id = c.content_id
    INNER JOIN content_genre cg ON c.content_id = cg.content_id
    INNER JOIN genre g ON cg.genre_id = g.genre_id
    WHERE 
        c.content_id NOT IN (
            SELECT vh.content_id FROM view_history vh WHERE vh.user_id = user_id_input
        ) -- Exclude already watched content
    ORDER BY 
        suc.avg_rating DESC, -- Prioritize highest-rated content
        c.rating DESC; -- Prioritize overall rating
END;
$$ LANGUAGE plpgsql;*/
