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


--Trigger update view_time to last check point of an episode__
CREATE OR REPLACE FUNCTION update_view_time()
RETURNS TRIGGER AS $$
BEGIN
	UPDATE View_history
END;
$$ LANGUAGE plpsql;