--/*
CREATE INDEX IF NOT EXISTS idx_view_history_user_time 
	ON view_history USING btree (user_id, view_time DESC, content_id);
CREATE INDEX IF NOT EXISTS idx_view_history_content_id 
	ON view_history USING brin (content_id);
CREATE INDEX IF NOT EXISTS idx_users_user_country 
	ON users USING btree(user_id, country_id);
CREATE INDEX IF NOT EXISTS idx_content_genre_content_genre 
	ON content_genre USING btree (content_id, genre_id);
CREATE INDEX IF NOT EXISTS idx_content_id 
	ON content USING btree (content_id);
CREATE INDEX IF NOT EXISTS idx_content_rating 
	ON content USING btree (rating DESC);
CREATE INDEX IF NOT EXISTS idx_genre_id 
	ON genre USING btree (genre_id);
CREATE INDEX idx_subscription_active 
	ON subscription USING btree (user_id) WHERE end_time = 'infinity';

CREATE EXTENSION pg_trgm;

CREATE INDEX idx_casts_first_name 
	ON casts USING gin (lower(first_name) gin_trgm_ops);
CREATE INDEX idx_casts_last_name 
	ON casts USING gin (lower(last_name) gin_trgm_ops);
CREATE INDEX idx_content_title 
	ON content USING gin (lower(title) gin_trgm_ops);
CREATE INDEX idx_genre_name 
	ON genre USING gin (lower(genre_name) gin_trgm_ops);

--*/
/*
DROP INDEX IF EXISTS idx_view_history_user_time;
DROP INDEX IF EXISTS idx_view_history_content_id;
DROP INDEX IF EXISTS idx_users_user_country;
DROP INDEX IF EXISTS idx_content_genre_content_genre;
DROP INDEX IF EXISTS idx_content_id;
DROP INDEX IF EXISTS idx_content_rating;
DROP INDEX IF EXISTS idx_genre_id;
DROP INDEX IF EXISTS idx_subscription_active;
DROP INDEX IF EXISTS idx_casts_first_name;
DROP INDEX IF EXISTS idx_casts_last_name;
DROP INDEX IF EXISTS idx_content_title;
DROP INDEX IF EXISTS idx_genre_name;
*/