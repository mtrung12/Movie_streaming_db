INSERT INTO Country (country_name) VALUES ('USA'), ('UK'), ('India');
INSERT INTO Users (first_name, last_name, email, password, country_id) 
VALUES 
('John', 'Doe', 'john.doe@example.com', 'Password@123', 1),
('Jane', 'Smith', 'jane.smith@example.com', 'Strong#Pass1', 2),
('Raj', 'Kumar', 'raj.kumar@example.com', 'Secure$789', 3);
INSERT INTO Content (title, release_date, director, content_type, access_level) 
VALUES 
('Movie A', '2023-01-01', 'Director A', 'movie', 1),
('Series B', '2022-05-15', 'Director B', 'series', 2),
('Movie C', '2024-03-10', 'Director C', 'movie', 3);
-- Insert initial ratings
INSERT INTO Rate (content_id, user_id, rating) 
VALUES 
(1, 1, 4.0),
(1, 2, 5.0),
(2, 1, 3.5);

-- Add another rating for Content 1 to see if the average updates
INSERT INTO Rate (content_id, user_id, rating) 
VALUES 
(1, 3, 3.0);

-- Check the updated rating in the Content table
SELECT content_id, title, rating 
FROM Content;



