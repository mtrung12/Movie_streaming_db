-- ============================
-- 1. DELETE Users
-- ============================
SELECT *
FROM Users
WHERE email IN (
    'sebastian.allen@example.com', 
    'amelia.taylor@example.com', 
    'raj.kumar@example.com'
);

SELECT * FROM Rate where user_id between 747 and 748;
SELECT * FROM Favourite_list where user_id between 747 and 748;
SELECT * FROM Subscription where user_id between 747 and 748;

DELETE FROM Users
WHERE email IN (
    'sebastian.allen@example.com', 
    'amelia.taylor@example.com', 
    'raj.kumar@example.com'
);

SELECT *
FROM Users
WHERE email IN (
    'sebastian.allen@example.com', 
    'amelia.taylor@example.com', 
    'raj.kumar@example.com'
);
SELECT * FROM Rate where user_id between 747 and 748;
SELECT * FROM Favourite_list where user_id between 747 and 748;
SELECT * FROM Subscription where user_id between 747 and 748;

-- This should delete the first 2 users along with their corresponding records in rate, subscription, and favourite_list
-- ============================

-- ============================
-- 2. INSERT New Users
-- ============================
-- show subscription_table first (no id 1, 2, 3)
SELECT * FROM subscription
WHERE user_id BETWEEN 1 AND 3;

INSERT INTO Users (first_name, last_name, email, password, country_id) 
VALUES 
    ('Sebastian', 'Allen', 'sebastian.allen@example.com', 'Password@123', 1),
    ('Amelia', 'Taylor', 'amelia.taylor@example.com', 'Strong#Pass1', 2),
    ('Raj', 'Kumar', 'raj.kumar@example.com', 'Secure$789', 3);

-- Display all users ordered by user_id
SELECT * FROM users ORDER BY user_id;
-- ============================

-- ============================
-- 3. Check Trigger for New User Pack
-- ============================
SELECT * FROM subscription
WHERE user_id BETWEEN 1 AND 3;
-- ============================

-- ============================
-- 4. Demo for Subscribing Functionalities
-- ============================
-- Show subscription_pack table
SELECT * FROM subscription
WHERE user_id BETWEEN 1 AND 3;

-- Attempt to subscribe a user to the same level pack
SELECT subscribe_to_pack(1, 1);  -- Should raise exception (user cannot subscribe to default pack)

-- Subscribe user 2 to level 2 pack
SELECT subscribe_to_pack(2, 2);
SELECT *
FROM Subscription
WHERE user_id = 2;

-- Subscribe user 3 to level 3 pack
SELECT subscribe_to_pack(3, 4);
SELECT *
FROM Subscription
WHERE user_id = 3;
-- User 2 subscribed to level 2 access pack, user 3 subscribed to level 3 access pack
-- ============================

-- ============================
-- 5. Check Trigger for Overlapping Subscription
-- ============================
-- This will raise an exception
SELECT subscribe_to_pack(2, 3);  -- Overlapping subscription for user 2

-- This will cancel current subscription and subscribe to a new pack
SELECT subscribe_to_pack(2, 4);
SELECT *
FROM Subscription
WHERE user_id = 2;

-- Check user 2's subscription
SELECT * FROM subscription WHERE user_id = 2;
SELECT *
FROM Subscription
WHERE user_id = 2;
-- ============================

-- ============================
-- 6. Test Unsubscribe Functionality
-- ============================
-- This will raise exception
SELECT unsubscribe(1); 

-- View before unsubscribe
SELECT *
FROM Subscription
WHERE user_id = 2;
-- This will cancel current subscription and automatically subscribe to a default pack
SELECT unsubscribe(2);
SELECT *
FROM Subscription
WHERE user_id = 2;

-- After unsubscribed, cannot unsub again if have not sub to a higher level pack
SELECT unsubscribe(2);

SELECT subscribe_to_pack(2, 3);
-- ============================

-- ============================
-- 7. Demo Trigger for Managing Access Level
-- ============================
-- Access level 1, 2, 3 for content IDs 111, 112, 116
-- Current access levels for user_id 1, 2, 3 are (1, 2, 2)
SELECT * FROM content
WHERE content_id IN (111, 112, 116);

-- This will raise an exception (access level conflict)
INSERT INTO View_history
VALUES(1, 112, 1, CURRENT_TIMESTAMP, '00:00:01', FALSE);

-- These will NOT raise an exception
INSERT INTO View_history
VALUES(1, 111, 1, CURRENT_TIMESTAMP, '00:00:01', FALSE);
SELECT * FROM view_history WHERE user_id = 1;

INSERT INTO View_history
VALUES(2, 112, 1, CURRENT_TIMESTAMP, '00:10:00', TRUE);
SELECT * FROM view_history WHERE user_id = 2;

-- Try to unsubscribe then watch level 2 content
SELECT * FROM subscription 
WHERE user_id = 2
ORDER BY start_time DESC;

SELECT unsubscribe(2);

INSERT INTO View_history
VALUES(2, 112, 1, CURRENT_TIMESTAMP, '00:20:00', TRUE);

-- ============================

-- ============================
-- 8. Check Trigger for Managing Ratings
-- ============================
-- This will raise exception because user ID 1 hasn't finished content 111
SELECT * 
FROM view_history WHERE user_id = 1;

INSERT INTO rate
VALUES(111, 1, CURRENT_TIMESTAMP, 4);

-- This will NOT raise exception because user ID 2 has finished content 112
SELECT * FROM content WHERE content_id = 112;

SELECT * 
FROM view_history 
WHERE user_id = 2 AND content_id = 112;

-- Check the content before inserting rating
SELECT * FROM content WHERE content_id = 112;

INSERT INTO rate
VALUES(112, 2, CURRENT_TIMESTAMP, 4);

-- Check the content before inserting rating
SELECT * FROM content WHERE content_id = 112;

-- Check Trigger: Delete old rating
-- This will update the rating
INSERT INTO rate
VALUES(112, 2, CURRENT_TIMESTAMP, 5.0);

-- Check content rating after update
SELECT * FROM rate WHERE content_id = 112;
SELECT * FROM content WHERE content_id = 112;
-- ============================

-- ============================
-- 9. Update Ratings
-- ============================
SELECT * FROM view_history WHERE user_id = 700;
SELECT * FROM subscription WHERE user_id = 700;

-- add another view and rating
INSERT INTO View_history
VALUES(700, 112, 1, CURRENT_TIMESTAMP, '00:10:00', TRUE);

-- Insert rating for user 700
INSERT INTO rate
VALUES(112, 700, CURRENT_TIMESTAMP, 4.0);

-- Check updated content after rating
SELECT * FROM content WHERE content_id = 112;
-- ============================

-- ============================
-- 10. Demo for Recommendation Functions
-- ============================
-- Recommend content based on genre for user 680 (genre_id = 3)
-- First, view what genre an user has watched
SELECT 
    v.user_id, 
    c.content_id, 
    c.title, 
    STRING_AGG(DISTINCT g.genre_name, ', ' ORDER BY g.genre_name) AS genres
FROM 
    view_history v
JOIN content c ON c.content_id = v.content_id
JOIN content_genre cg ON c.content_id = cg.content_id
JOIN genre g ON cg.genre_id = g.genre_id
WHERE v.user_id = 680
GROUP BY v.user_id, c.content_id, c.title
ORDER BY c.title;

SELECT * FROM recommend_content_by_genre(680, 3);

-- Recommend content based on location for user 680
-- View contents watched most by country belong to a specific user
SELECT 
	c.content_id AS recommended_content_id,
	c.title,
	c.rating
FROM 
	view_history vh
INNER JOIN content c ON vh.content_id = c.content_id
INNER JOIN users u ON vh.user_id = u.user_id
WHERE u.country_id = (SELECT country_id FROM users WHERE user_id = 680)
GROUP BY c.content_id, c.title, c.rating
ORDER BY COUNT(vh.content_id) DESC, c.rating DESC;

SELECT * FROM recommend_content_by_location(680);
-- ============================

-- ============================
-- 11. Search content by keyword function
-- ============================
SELECT * FROM search_content_by_keyword('the');

-- ============================
-- 12. Search content by keyword function
-- ============================
-- test these 2 functions on mass database
SELECT * FROM recommend_content_by_genre(130003);
SELECT * FROM recommend_content_by_location(130003);