
CREATE TYPE user_status AS ENUM ('active', 'inactive');
CREATE TYPE content_type_enum AS ENUM ('movie', 'series');
CREATE TYPE user_level_enum AS ENUM ('Free', 'Standard', 'Pro');
CREATE TYPE duration_enum AS ENUM ('6', '12', 'infinity'); 

CREATE TABLE Country (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(255) NOT NULL
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
    country_id INT NOT NULL,
    FOREIGN KEY (country_id) REFERENCES Country(country_id) ON DELETE SET NULL
);

CREATE TABLE Content (
    content_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    release_date DATE,
    director VARCHAR(100),

    rating DECIMAL(3, 1) CHECK (rating BETWEEN 1 AND 5),

    content_type content_type_enum NOT NULL,
    access_level INT CHECK (access_level BETWEEN 1 AND 3) DEFAULT 1 
);

CREATE TABLE Episode (
    content_id INT NOT NULL,
    episode_no INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    duration TIME NOT NULL,
    PRIMARY KEY (content_id, episode_no),
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE
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
    duration duration_enum NOT NULL, 
    access_level INT CHECK (access_level BETWEEN 1 AND 3) 
);

CREATE TABLE View_history (
    user_id INT NOT NULL,
    content_id INT NOT NULL,
    episode_no INT NOT NULL,
    view_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    check_point TIME NOT NULL,
    is_finished BOOLEAN DEFAULT FALSE NOT NULL,
    PRIMARY KEY (user_id, content_id, episode_no, view_time),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (content_id, episode_no) REFERENCES Episode(content_id, episode_no) ON DELETE CASCADE
);


CREATE TABLE Subscription (
    user_id INT NOT NULL,
    pack_id INT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP DEFAULT 'infinity',
    PRIMARY KEY (user_id, start_time, pack_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (pack_id) REFERENCES Subscription_pack(pack_id) ON DELETE CASCADE,
    CHECK (end_time > start_time)
);


CREATE TABLE Rate (
    content_id INT NOT NULL,
    user_id INT NOT NULL,
    time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5) NOT NULL,
    PRIMARY KEY (content_id, user_id),
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);


CREATE TABLE Favourite_list (
    content_id INT NOT NULL,
    user_id INT NOT NULL,
    PRIMARY KEY (content_id, user_id),
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Content_genre (
    content_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (content_id, genre_id),
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES Genre(genre_id) ON DELETE CASCADE
);

CREATE TABLE Content_cast (
    content_id INT NOT NULL,
    cast_id INT NOT NULL,
    PRIMARY KEY (content_id, cast_id),
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE,
    FOREIGN KEY (cast_id) REFERENCES Casts(cast_id) ON DELETE CASCADE
);

CREATE TABLE Language (
    language_id INT PRIMARY KEY,
    language_name VARCHAR(100) NOT NULL
);

CREATE TABLE Language_available (
    content_id INT NOT NULL,
    language_id INT NOT NULL,
    PRIMARY KEY (content_id, language_id),
    FOREIGN KEY (content_id) REFERENCES Content(content_id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES Language(language_id) ON DELETE CASCADE
);

CREATE TABLE Country_language (
    country_id INT NOT NULL,
    language_id INT NOT NULL,
    PRIMARY KEY (country_id, language_id),
    FOREIGN KEY (country_id) REFERENCES Country(country_id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES Language(language_id) ON DELETE CASCADE
);