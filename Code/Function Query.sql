CREATE OR REPLACE FUNCTION recommend_content_by_location(user_id_input INTEGER)
RETURNS TABLE (
    recommended_content_id INTEGER,
    title VARCHAR,
    genre_names VARCHAR, -- Aggregated genres
    rating DECIMAL(3, 1),
    view_count INTEGER -- Added view_count column
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.content_id AS recommended_content_id,
        c.title,
        STRING_AGG(DISTINCT g.genre_name, ', ')::VARCHAR AS genre_names, -- Cast to VARCHAR
        c.rating,
        COUNT(vh.content_id)::INTEGER AS view_count -- Cast COUNT to INTEGER
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
    rating DECIMAL(3, 1),
    view_count INTEGER -- Added view count
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
        STRING_AGG(DISTINCT g2.genre_name, ', ')::VARCHAR AS genre_names, -- Concatenate all genre names, remove duplicates
        c.rating,
        COUNT(DISTINCT vh.user_id)::INTEGER AS view_count -- Cast COUNT to INTEGER
    FROM 
        content c
    INNER JOIN content_genre cg ON c.content_id = cg.content_id
    LEFT JOIN genre g1 ON cg.genre_id = g1.genre_id -- First join for matching user preferred genres
    LEFT JOIN genre g2 ON cg.genre_id = g2.genre_id -- Second join to gather all genres for content
    LEFT JOIN view_history vh ON c.content_id = vh.content_id -- Join to count views for each content
    WHERE 
        g1.genre_id IN (SELECT genre_id FROM user_genre_preference) -- Match one of the top genres
        AND c.content_id NOT IN (
            SELECT vh.content_id FROM view_history vh WHERE vh.user_id = user_id_input
        ) -- Exclude already watched content
    GROUP BY 
        c.content_id, c.title, c.rating -- Group by content to avoid duplicates
    ORDER BY 
        view_count DESC, -- Most viewed content
        c.rating DESC, -- Highest-rated content
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
	closest_end_time TIMESTAMP;
BEGIN
    -- 1. Check if user attempt to subscribe to the default pack, if so, raise an exception
	
    IF NEW_PACK_ID = default_pack_id THEN
        RAISE EXCEPTION 'User is already on the default subscription pack.';
    END IF;

    -- 2. Update the current subscription's end_time to current time 
	-- (if the user has an active high level subscription)
	SELECT end_time INTO closest_end_time
		FROM subscription
		WHERE (user_id = NEW_USER_ID AND pack_id != default_pack_id)
		ORDER BY start_time DESC
	LIMIT 1;
	
	IF closest_end_time > CURRENT_TIMESTAMP THEN
		UPDATE subscription
		SET end_time = CURRENT_TIMESTAMP	
		WHERE user_id = NEW_USER_ID 
		  AND end_time = closest_end_time;
	END IF;
    
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
        END
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION unsubscribe(NEW_USER_ID INT)
RETURNS VOID AS $$
DECLARE
    default_pack_id INT := 1;
	closest_end_time TIMESTAMP;
BEGIN
    -- 1. Check if user is already on the default pack (pack_id = 1), if so, raise an exception
    SELECT end_time, pack_id INTO closest_end_time, current_pack_id
		FROM subscription
		WHERE user_id = NEW_USER_ID
		ORDER BY start_time DESC
	LIMIT 1;
    
    IF CURRENT_TIMESTAMP > closest_end_time OR current_pack_id = default_pack_id THEN
        RAISE EXCEPTION 'User does not have any active subscription.';
    END IF;

    -- 2. Update the current active subscription's end_time to NOW()
    UPDATE subscription
    SET end_time = CURRENT_TIMESTAMP
    WHERE user_id = NEW_USER_ID
      AND end_time > CURRENT_TIMESTAMP
	  AND pack_id != default_pack_id;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_content_by_keyword(search_keyword TEXT)
RETURNS TABLE (
    content_id INT,
    title VARCHAR,
    genre_names VARCHAR,
    cast_names VARCHAR,
    rating DECIMAL,
    view_count INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.content_id, 
        c.title,
        STRING_AGG(DISTINCT g.genre_name, ', ')::VARCHAR AS genre_names,
        STRING_AGG(DISTINCT CONCAT(cs.first_name, ' ', cs.last_name), ', ')::VARCHAR AS cast_names,
        c.rating,
        COALESCE(COUNT(vh.content_id), 0)::INT AS view_count  -- Explicitly cast COUNT to INT
    FROM 
        content c
    LEFT JOIN 
        content_genre cg ON c.content_id = cg.content_id
    LEFT JOIN 
        genre g ON cg.genre_id = g.genre_id
    LEFT JOIN 
        content_cast cc ON c.content_id = cc.content_id
    LEFT JOIN 
        casts cs ON cc.cast_id = cs.cast_id
    LEFT JOIN 
        view_history vh ON c.content_id = vh.content_id AND vh.is_finished = TRUE  -- Join view_history with condition on is_finished
    WHERE 
        LOWER(c.title) LIKE LOWER('%' || search_keyword || '%')
        OR LOWER(cs.first_name) LIKE LOWER('%' || search_keyword || '%')
        OR LOWER(cs.last_name) LIKE LOWER('%' || search_keyword || '%')
        OR LOWER(g.genre_name) LIKE LOWER('%' || search_keyword || '%')
    GROUP BY 
        c.content_id, c.title, c.rating
    ORDER BY 
        view_count DESC,
        c.rating DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql;