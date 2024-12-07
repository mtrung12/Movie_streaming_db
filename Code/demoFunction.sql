-- Demo for functions --

SELECT *
FROM recommend_content_by_genre(680, 3);

SELECT *
FROM recommend_content_by_location(680);

-- this should raise exception
SELECT subscribe_to_pack(680, 1);

-- this should also raise exception
SELECT unsubscribe(680);

SELECT subscribe_to_pack(680, 3);

-- this will cancel current subscription and subscribe to new pack
SELECT subscribe_to_pack(680, 5);

-- this will also cancel current subscription, automatically sub to a default pack
SELECT unsubscribe(680);
