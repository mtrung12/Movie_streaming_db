-- ============================
-- 1. DELETE Users
-- ============================
DELETE FROM Users
WHERE email IN (
    'john.doe1@example.com', 
    'jane.smith1@example.com', 
    'raj.kumar@example.com'
);

-- This should delete the first 2 users along with their corresponding records in rate, subscription, and favourite_list
-- ============================

-- ============================
-- 2. INSERT New Users
-- ============================
INSERT INTO Users (first_name, last_name, email, password, country_id) 
VALUES 
    ('John', 'Doe', 'john.doe@example.com', 'Password@123', 1),
    ('Jane', 'Smith', 'jane.smith@example.com', 'Strong#Pass1', 2),
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
-- Attempt to subscribe a user to the same level pack
SELECT subscribe_to_pack(1, 1);  -- Should raise exception (user at level 1 cannot subscribe to level 1 again)

-- Subscribe user 2 to level 2 pack
SELECT subscribe_to_pack(2, 2);

-- Subscribe user 3 to level 4 pack
SELECT subscribe_to_pack(3, 4);

-- Check the subscription table
SELECT * FROM subscription;
-- User 2 subscribed to level 2 access pack, user 3 subscribed to level 3 access pack
-- ============================

-- ============================
-- 5. Check Trigger for Overlapping Subscription
-- ============================
-- This will raise an exception
SELECT subscribe_to_pack(2, 3);  -- Overlapping subscription for user 2

-- This will cancel current subscription and subscribe to a new pack
SELECT subscribe_to_pack(2, 4);

-- Check user 2's subscription
SELECT * FROM subscription WHERE user_id = 2;
-- ============================

-- ============================
-- 6. Test Unsubscribe Functionality
-- ============================
-- This will raise exception
SELECT unsubscribe(680); 

-- This will cancel current subscription and automatically subscribe to a default pack
SELECT unsubscribe(680);
-- ============================

-- ============================
-- 7. Demo Trigger for Managing Access Level
-- ============================
-- Access level 1, 2, 3 for content IDs 111, 112, 116
-- Current access levels for user_id 1, 2, 3 are (1, 2, 2)

-- This will raise an exception (access level conflict)
INSERT INTO View_history
VALUES(1, 112, 1, CURRENT_TIMESTAMP, '00:00:01', FALSE);

-- These will NOT raise an exception
INSERT INTO View_history
VALUES(1, 111, 1, CURRENT_TIMESTAMP, '00:00:01', FALSE);

INSERT INTO View_history
VALUES(2, 112, 1, CURRENT_TIMESTAMP, '00:10:00', TRUE);
-- ============================

-- ============================
-- 8. Check Trigger for Managing Ratings
-- ============================
-- This will raise exception because user ID 1 hasn't finished content 111
INSERT INTO rate
VALUES(111, 1, CURRENT_TIMESTAMP, 4);

-- This will NOT raise exception because user ID 2 has finished content 112
INSERT INTO rate
VALUES(112, 2, CURRENT_TIMESTAMP, 4);

-- Check the content before inserting rating
SELECT * FROM content WHERE content_id = 112;

-- Check Trigger: Delete old rating
-- This will update the rating
INSERT INTO rate
VALUES(112, 2, CURRENT_TIMESTAMP, 3.0);

-- Check content rating after update
SELECT * FROM content WHERE content_id = 112;
-- ============================

-- ============================
-- 9. Insert View History and Update Ratings
-- ============================
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