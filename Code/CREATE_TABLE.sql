CREATE TYPE user_status AS ENUM ('active', 'inactive');
CREATE TYPE content_type_enum AS ENUM ('movie', 'series');
CREATE TYPE user_level_enum AS ENUM ('Free', 'Standard', 'Pro');

CREATE TABLE Region (
    region_id SERIAL PRIMARY KEY,
    region_name VARCHAR(255) NOT NULL
);

CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL CHECK (
        LENGTH(password) >= 8 AND
        password ~ '[A-Z]' AND  -- ít nhất một chữ cái viết hoa
        password ~ '[a-z]' AND  -- ít nhất một chữ cái viết thường
        password ~ '[0-9]' AND  -- ít nhất một chữ số
        password ~ '[!@#$%^&*(),.?":{}|<>]'  -- ít nhất một ký tự đặc biệt
    ),
    status user_status DEFAULT 'active',
    region_id INT,
    FOREIGN KEY (region_id) REFERENCES Region(region_id) ON DELETE SET NULL
);

CREATE TABLE Content (
    content_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    release_date DATE,
    director VARCHAR(100),
    rating DECIMAL(3, 1) CHECK (rating BETWEEN 0 AND 10),
    content_type content_type_enum NOT NULL,
    min_access INT CHECK (min_access BETWEEN 1 AND 3)
);

CREATE TABLE Genre (
    genre_id SERIAL PRIMARY KEY,
    genre_name VARCHAR(100) NOT NULL
);

CREATE TABLE Casts (
    cast_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL
);

CREATE TABLE Subscription_pack (
    pack_id SERIAL PRIMARY KEY,
    pack_name VARCHAR(255) NOT NULL,
    price DECIMAL(8, 2) NOT NULL,
    access_level INT CHECK (access_level BETWEEN 1 AND 3),
    duration INT CHECK (duration > 0)
);

CREATE TABLE User_level (
    level_id SERIAL PRIMARY KEY,
    level_name user_level_enum NOT NULL
);

CREATE TABLE Episode (
    content_id INT NOT NULL,
    episode_no INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    duration INT NOT NULL CHECK (duration > 0),
    PRIMARY KEY (content_id, episode_no),
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE
);

CREATE TABLE View_history (
    view_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    content_id INT NOT NULL,
    view_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    check_point TIME NOT NULL,
    is_finished BOOLEAN DEFAULT FALSE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE
);

CREATE TABLE Subscription (
    subscription_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    CHECK (end_date > start_date)
);

CREATE TABLE Rate (
    rate_id SERIAL PRIMARY KEY,
    content_id INT NOT NULL,
    user_id INT NOT NULL,
    time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    rating DECIMAL(3, 1) CHECK (rating BETWEEN 0 AND 10) NOT NULL,
    FOREIGN KEY (content_id) REFERENCES Content(content_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Content_genre (
    content_genre_id SERIAL PRIMARY KEY,
    content_id INT NOT NULL,
    genre_id INT NOT NULL,
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES Genre(genre_id) ON DELETE CASCADE
);

CREATE TABLE Content_actor (
    content_actor_id SERIAL PRIMARY KEY,
    content_id INT NOT NULL,
    cast_id INT NOT NULL,
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE,
    FOREIGN KEY (cast_id) REFERENCES Casts(cast_id) ON DELETE CASCADE
);

CREATE TABLE Subtitle (
    subtitle_id SERIAL PRIMARY KEY,
    subtitle_name VARCHAR(100) NOT NULL
);

CREATE TABLE Country_subtitle (
    country_subtitle_id SERIAL PRIMARY KEY,
    subtitle_id INT NOT NULL,
    country_id INT NOT NULL,
    FOREIGN KEY (subtitle_id) REFERENCES Subtitle(subtitle_id) ON DELETE CASCADE,
    FOREIGN KEY (country_id) REFERENCES Region(region_id) ON DELETE CASCADE
);

CREATE TABLE Subtitle_available (
    subtitle_available_id SERIAL PRIMARY KEY,
    content_id INT NOT NULL,
    subtitle_id INT NOT NULL,
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE,
    FOREIGN KEY (subtitle_id) REFERENCES Subtitle(subtitle_id) ON DELETE CASCADE
);
