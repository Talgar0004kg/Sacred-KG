-- ============================================
-- Sacred KG — Схема базы данных Supabase
-- ============================================

-- 1. МЕСТА (сакральные места)
CREATE TABLE places (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_ru TEXT NOT NULL,
    title_kg TEXT,
    title_en TEXT,
    description_ru TEXT,
    description_kg TEXT,
    description_en TEXT,
    region TEXT NOT NULL,          -- batken, chuy, issyk_kul, jalal_abad, naryn, osh, talas
    category TEXT DEFAULT 'sacred', -- sacred, petroglyph, spring, route
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    image_url TEXT,
    cultural_notes_ru TEXT,
    cultural_notes_kg TEXT,
    cultural_notes_en TEXT,
    route_guidance_ru TEXT,
    route_guidance_kg TEXT,
    route_guidance_en TEXT,
    is_featured BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ПОЛЬЗОВАТЕЛИ
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT,
    role TEXT DEFAULT 'user',     -- user, admin
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ИЗБРАННОЕ
CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    place_id UUID REFERENCES places(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, place_id)
);

-- 4. БРОНИРОВАНИЯ ПОСЕЩЕНИЙ
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    place_id UUID REFERENCES places(id) ON DELETE CASCADE,
    visit_date DATE NOT NULL,
    guests INTEGER DEFAULT 1,
    status TEXT DEFAULT 'pending', -- pending, confirmed, cancelled
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. ОТЗЫВЫ
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    place_id UUID REFERENCES places(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment_ru TEXT,
    comment_kg TEXT,
    comment_en TEXT,
    is_approved BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ПОСТЫ СООБЩЕСТВА
CREATE TABLE community_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content_ru TEXT,
    content_kg TEXT,
    content_en TEXT,
    image_url TEXT,
    place_id UUID REFERENCES places(id) ON DELETE SET NULL,
    is_approved BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. AI-ЧАТ (история диалогов с DeepSeek)
CREATE TABLE ai_chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    place_id UUID REFERENCES places(id) ON DELETE SET NULL,
    character_mode TEXT DEFAULT 'atashka', -- atashka, apashka
    message TEXT NOT NULL,
    response TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. НАСТРОЙКИ AI-ГИДА (административные)
CREATE TABLE ai_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Индексы
CREATE INDEX idx_places_region ON places(region);
CREATE INDEX idx_places_category ON places(category);
CREATE INDEX idx_places_active ON places(is_active);
CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_reviews_place ON reviews(place_id);
CREATE INDEX idx_favorites_user ON favorites(user_id);

-- Заполнение начальных настроек AI
INSERT INTO ai_config (key, value, description) VALUES
    ('ai_model', 'deepseek-chat', 'Модель DeepSeek для AI-гида'),
    ('ai_temperature', '0.7', 'Температура генерации'),
    ('atashka_prompt', 'Ты Аташка — хранитель истории Кыргызстана. Рассказывай о сакральных местах с мудростью старца. Используй легенды, эпос Манас, народные сказания. Говори как аксакал.', 'Системный промпт для режима Аташка'),
    ('apashka_prompt', 'Ты Апашка — традиционный гид Кыргызстана. Рассказывай о местах тепло и душевно, как бабушка у очага. Делись народными традициями, рецептами, обычаями. Говори ласково.', 'Системный промпт для режима Апашка');
