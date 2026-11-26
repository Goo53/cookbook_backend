CREATE TABLE meals (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    image_url TEXT NOT NULL,
    duration INTEGER NOT NULL,
    complexity TEXT NOT NULL,
        CHECK (complexity IN ('simple', 'challenging', 'hard')),
    affordability TEXT NOT NULL,
        CHECK (affordability IN ('affordable', 'pricey', 'luxurious')),
    is_meat BOOLEAN NOT NULL DEFAULT FALSE,
    is_vegetarian BOOLEAN NOT NULL DEFAULT FALSE,
    categories JSONB NOT NULL DEFAULT '[]'::jsonb,
    ingredients JSONB NOT NULL DEFAULT '[]'::jsonb,
    steps JSONB NOT NULL DEFAULT '[]'::jsonb
);

CREATE TABLE favorites (
    meal_id TEXT PRIMARY KEY REFERENCES meals(id) ON DELETE CASCADE
);