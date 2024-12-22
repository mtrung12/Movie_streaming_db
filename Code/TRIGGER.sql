--TRIGGER 1--
-- Trigger to calculate and update the average rating
CREATE OR REPLACE FUNCTION update_content_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the content's rating based on the average of user ratings
    UPDATE Content
    SET rating = (
        SELECT COALESCE(AVG(rating), 0)
        FROM Rate
        WHERE content_id = NEW.content_id
    )
    WHERE content_id = NEW.content_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Trigger for INSERT and UPDATE on the Rate table
CREATE TRIGGER rate_update_trigger
AFTER INSERT OR UPDATE ON Rate
FOR EACH ROW
EXECUTE FUNCTION update_content_rating();
-- Trigger for DELETE on the Rate table
CREATE TRIGGER rate_delete_trigger
AFTER DELETE ON Rate
FOR EACH ROW
EXECUTE FUNCTION update_content_rating();


--TRIGGER 2--
 -- Check if there is an overlapping subscription with the same or higher access level
CREATE OR REPLACE FUNCTION check_subscription_overlap()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.pack_id != 1 AND EXISTS (
        SELECT 1
        FROM Subscription AS s
        JOIN Subscription_pack AS sp ON s.pack_id = sp.pack_id
        WHERE 
            s.user_id = NEW.user_id
            AND s.end_time >= CURRENT_TIMESTAMP  -- Active subscription
            AND sp.access_level >= (
                SELECT access_level 
                FROM Subscription_pack 
                WHERE pack_id = NEW.pack_id
            )
    ) THEN
        RAISE EXCEPTION 'Cannot subscribe to a pack with an access level that is not higher than that of the current active subscription.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--Create trigger--
CREATE TRIGGER prevent_subscription_overlap
BEFORE INSERT ON Subscription
FOR EACH ROW
EXECUTE FUNCTION check_subscription_overlap();


--TRIGGER 3--
--Automatically connect a new user with free pack--
CREATE OR REPLACE FUNCTION new_user_pack()
RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO Subscription (user_id, pack_id, start_time, end_time)
    VALUES (NEW.user_id, 1, CURRENT_DATE, 'infinity'); -- Set end time to infinity
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Create the trigger
CREATE TRIGGER new_user_pack
AFTER INSERT ON Users
FOR EACH ROW
EXECUTE FUNCTION new_user_pack();


--TRIGGER 4--
-- Check if the user has finished watching at least one episode of the content
CREATE OR REPLACE FUNCTION check_user_watch_status() 
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM View_history
        WHERE user_id = NEW.user_id 
        AND content_id = NEW.content_id
        AND is_finished = TRUE
    ) THEN
        -- Raise an exception if the user hasn't finished any episode
        RAISE EXCEPTION 'User must finish watching at least one episode of the content before rating.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--Create trigger--
CREATE TRIGGER check_user_can_rate_content
BEFORE INSERT ON Rate
FOR EACH ROW
EXECUTE FUNCTION check_user_watch_status();

--TRIGGER 5--
-- Trigger to check if the user can access the content --
CREATE OR REPLACE FUNCTION check_user_access()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Subscription s
        JOIN Subscription_pack sp ON s.pack_id = sp.pack_id
        WHERE s.user_id = NEW.user_id
        AND s.end_time > CURRENT_DATE
        AND sp.access_level >= (
            SELECT c.access_level
            FROM Content c
            WHERE c.content_id = NEW.content_id
        )
    ) THEN
        RAISE EXCEPTION 'User does not have access to the content';
    END IF;
    -- If access is valid, proceed with inserting into View_history
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_check_user_access
BEFORE INSERT ON View_history
FOR EACH ROW
EXECUTE FUNCTION check_user_access();

--TRIGGER 6--
-- Delete old rating from the same user for the same content
CREATE OR REPLACE FUNCTION delete_old_rating()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM Rate
    WHERE user_id = NEW.user_id
      AND content_id = NEW.content_id;

    -- Allow the new rating to be inserted
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--Create trigger--
CREATE TRIGGER before_rate_insert
BEFORE INSERT ON Rate
FOR EACH ROW
EXECUTE FUNCTION delete_old_rating();


--TRIGGER 7--
CREATE OR REPLACE FUNCTION deactive_old_pack()
RETURNS TRIGGER AS $$
BEGIN 
	UPDATE Subscription
	SET end_time = CURRENT_TIMESTAMP + INTERVAL '1 second'
	WHERE user_id = NEW.user_id
	AND end_time >= CURRENT_TIMESTAMP
	AND pack_id != 1
	AND pack_id != NEW.pack_id;
	RETURN NEW;
END;
$$LANGUAGE plpgsql;
--Create trigger
CREATE TRIGGER deactive_old_pack
AFTER INSERT ON Subscription
FOR EACH ROW
EXECUTE FUNCTION deactive_old_pack();