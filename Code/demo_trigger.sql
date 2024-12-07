-- Clear demo --
DELETE FROM Users
WHERE email IN (
    'john.doe@example.com', 
    'jane.smith@example.com', 
    'raj.kumar@example.com'
);

-- Insert new users --
INSERT INTO Users (user_id, first_name, last_name, email, password, country_id) 
VALUES 
(1, 'John', 'Doe', 'john.doe@example.com', 'Password@123', 1),
(2, 'Jane', 'Smith', 'jane.smith@example.com', 'Strong#Pass1', 2),
(3, 'Raj', 'Kumar', 'raj.kumar@example.com', 'Secure$789', 3);

--Check trigger new_user_pack--
SELECT * FROM subscription
WHERE user_id BETWEEN 1 AND 3;

--Add subscription pack 1,2,4 (access_level=1,2,3) for user_id 1,2,3 respectively 
INSERT INTO subscription(user_id, pack_id, start_time, end_time)
VALUES(2, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP+INTERVAL '2 days'), 
		(3, 4, CURRENT_TIMESTAMP-INTERVAL '3 days', CURRENT_TIMESTAMP-INTERVAL '1 day');
SELECT * FROM subscription
WHERE user_id BETWEEN 1 AND 3;

-- Check trigger overlapping subscription --
--This will raise EXCEPTION <-- pack 3 have access_level = 2 equal to pack 2
INSERT INTO subscription(user_id, pack_id, start_time, end_time)
VALUES(2, 3, CURRENT_DATE, CURRENT_DATE+2);
		
--This will NOT raise EXCEPTION <-- pack 4 have access_level = 3 > pack 3 but it expired 
INSERT INTO subscription(user_id, pack_id, start_time, end_time)
VALUES(3, 3, CURRENT_DATE, CURRENT_DATE+2);

--RUN thí to check trigger deactive_old_pack
SELECT * FROM subscription
WHERE user_id = 3;

--content_id in (111,112,116) --> access level (1, 2, 3)
--current access level of user_id(1, 2, 3) is (1, 2, 2)\
--Demo trigger: manage access level
--This will raise an EXCEPTION
INSERT INTO View_history
VALUES(1,112,1,CURRENT_TIMESTAMP,'00:00:01', FALSE);
--These will NOT raise an EXCEPTION
INSERT INTO View_history
VALUES(1,111,1,CURRENT_TIMESTAMP,'00:00:01', FALSE);

INSERT INTO View_history
VALUES(2,112,1,CURRENT_TIMESTAMP,'00:00:01', TRUE);

--Check trigger: manage rating
--This will raise exception because user ID 1 haven't finished movies 111
INSERT INTO rate
VALUES(111,1,CURRENT_TIMESTAMP, 4.0);
--This will NOT raise exception because user ID 2 haven finished movies 112
INSERT INTO rate
VALUES(112,2,CURRENT_TIMESTAMP, 4.0)


--Check trigger: AVG rating
SELECT * FROM content
WHERE content_id=112;

--Check trigger: delete old rating
--Run Check trigger: AVG rating after to observe the result of this
INSERT INTO rate
VALUES(112,2,CURRENT_TIMESTAMP, 3.0)
