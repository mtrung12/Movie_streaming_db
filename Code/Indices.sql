--/*
CREATE INDEX IF NOT EXISTS idx_view_history_content_id 
	ON view_history USING brin (content_id);
CREATE INDEX IF NOT EXISTS idx_content_genre_content_genre 
	ON content_genre USING btree (content_id, genre_id);
CREATE INDEX IF NOT EXISTS idx_content_id 
	ON content USING btree (content_id);
CREATE INDEX IF NOT EXISTS idx_genre_id 
	ON genre USING btree (genre_id);

--*/
/*
DROP INDEX IF EXISTS idx_view_history_content_id;
DROP INDEX IF EXISTS idx_content_genre_content_genre;
DROP INDEX IF EXISTS idx_content_id;
DROP INDEX IF EXISTS idx_genre_id;
*/