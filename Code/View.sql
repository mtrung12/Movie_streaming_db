-- Subscription History View
CREATE VIEW UserSubscriptionHistory AS
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    s.pack_id,
    sp.pack_name,
    sp.price,
    s.start_time,
    s.end_time
FROM 
    Users u
JOIN 
    Subscription s ON u.user_id = s.user_id
JOIN 
    Subscription_pack sp ON s.pack_id = sp.pack_id;

-- Favorite List View
CREATE VIEW UserFavoriteList AS
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    c.title AS content_title,
    c.content_type,
    c.rating
FROM 
    Favourite_list f
JOIN 
    Users u ON f.user_id = u.user_id
JOIN 
    Content c ON f.content_id = c.content_id;

-- Watch history view
CREATE VIEW UserWatchHistory AS
SELECT 
    vh.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    c.title AS content_title,
    e.episode_no,
    vh.check_point,
    vh.is_finished,
    vh.view_time
FROM 
    View_history vh
JOIN 
    Users u ON vh.user_id = u.user_id
JOIN 
    Content c ON vh.content_id = c.content_id
LEFT JOIN 
    Episode e ON vh.content_id = e.content_id AND vh.episode_no = e.episode_no;

-- Content Management
CREATE VIEW ContentManagement AS
SELECT 
    c.content_id,
    c.title,
    c.release_date,
    c.director,
    c.rating,
    c.content_type,
    c.access_level,
    STRING_AGG(g.genre_name, ', ') AS genres
FROM 
    Content c
LEFT JOIN 
    Content_genre cg ON c.content_id = cg.content_id
LEFT JOIN 
    Genre g ON cg.genre_id = g.genre_id
GROUP BY 
    c.content_id;

-- Episode Details View
CREATE VIEW EpisodeManagement AS
SELECT 
    e.content_id,
    c.title AS series_title,
    e.episode_no,
    e.title AS episode_title,
    e.duration
FROM 
    Episode e
JOIN 
    Content c ON e.content_id = c.content_id
WHERE 
    c.content_type = 'series';

-- User Account Management View
CREATE VIEW UserManagement AS
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    u.email,
    u.status,
    c.country_name
FROM 
    Users u
LEFT JOIN 
    Country c ON u.country_id = c.country_id;



-- Top Rated Content View
CREATE VIEW TopRatedContent AS
SELECT 
    c.content_id,
    c.title,
    c.rating,
    STRING_AGG(g.genre_name, ', ') AS genres
FROM 
    Content c
LEFT JOIN 
    Content_genre cg ON c.content_id = cg.content_id
LEFT JOIN 
    Genre g ON cg.genre_id = g.genre_id
WHERE 
    c.rating IS NOT NULL
GROUP BY 
    c.content_id
ORDER BY 
    c.rating DESC
limit 10;

select * from UserSubscriptionHistory
select * from UserFavoriteList
select * from UserWatchHistory
select * from ContentManagement
select * from EpisodeManagement
select * from UserManagement
select * from TopRatedContent

