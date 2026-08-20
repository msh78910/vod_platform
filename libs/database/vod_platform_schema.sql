-- =====================================================================
-- VOD Platform — Database Schema (PostgreSQL)
-- =====================================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid()

-- =====================================================================
-- 1. هویت انسانی (Person) — بازیگر، کارگردان، کارمند، بیننده... بدون نیاز به لاگین
-- =====================================================================
CREATE TABLE person (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    birth_date  DATE,
    bio         TEXT,
    photo_url   TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_person_birth_date CHECK (birth_date IS NULL OR birth_date <= CURRENT_DATE)
);

-- =====================================================================
-- 2. شرکت‌ها
-- =====================================================================
CREATE TABLE company (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                 VARCHAR(255) NOT NULL,
    registration_number  VARCHAR(100) UNIQUE,
    national_id          VARCHAR(100),
    address              TEXT,
    is_verified          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================================
-- 3. حساب کاربری (Account) — لایه‌ی احراز هویت، جدا از Person/Company
--    دقیقا یکی از person_id یا company_id باید پر باشد
-- =====================================================================
CREATE TABLE account (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id      UUID REFERENCES person(id)  ON DELETE CASCADE,
    company_id     UUID REFERENCES company(id) ON DELETE CASCADE,
    username       VARCHAR(50)  NOT NULL UNIQUE,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password_hash  TEXT NOT NULL,
    joined_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_account_owner CHECK (
        (person_id IS NOT NULL AND company_id IS NULL) OR
        (person_id IS NULL AND company_id IS NOT NULL)
    )
);
CREATE INDEX idx_account_person  ON account(person_id);
CREATE INDEX idx_account_company ON account(company_id);

-- =====================================================================
-- 4. کارمندان (Employee) و نقش‌ها (RBAC به‌جای لیست/آرایه)
-- =====================================================================
CREATE TABLE employee (
    account_id       UUID PRIMARY KEY REFERENCES account(id) ON DELETE CASCADE,
    hire_date        DATE NOT NULL,
    salary           NUMERIC(12,2),                 -- برای کارمند ماهیانه
    employment_type  VARCHAR(20) NOT NULL DEFAULT 'salaried', -- salaried | commission
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_employee_salary CHECK (salary IS NULL OR salary >= 0)
);

CREATE TABLE role (
    id           SMALLSERIAL PRIMARY KEY,
    name         VARCHAR(50) NOT NULL UNIQUE,   -- admin, operator, hr, moderator, critique...
    description  TEXT
);

CREATE TABLE employee_role (            -- جدول واسط many-to-many به‌جای ستون لیست
    employee_id  UUID     REFERENCES employee(account_id) ON DELETE CASCADE,
    role_id      SMALLINT REFERENCES role(id) ON DELETE RESTRICT,
    granted_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    granted_by   UUID REFERENCES employee(account_id),
    PRIMARY KEY (employee_id, role_id)
);

-- DEPENDENT_OF: اعضای خانواده کارمند (بیمه، پاداش و...)
CREATE TABLE dependent (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id  UUID NOT NULL REFERENCES employee(account_id) ON DELETE CASCADE,
    full_name    VARCHAR(200) NOT NULL,
    relation     VARCHAR(30)  NOT NULL,  -- spouse | child | parent ...
    birth_date   DATE,
    national_id  VARCHAR(50),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_dependent_employee ON dependent(employee_id);

-- =====================================================================
-- 5. اشتراک‌ها — تاریخچه‌ی خرید به‌جای لیست/آرایه در ردیف کاربر
-- =====================================================================
CREATE TABLE subscription_plan (
    id             SMALLSERIAL PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    price          NUMERIC(10,2) NOT NULL,
    duration_days  INT NOT NULL CHECK (duration_days > 0),
    is_active      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE subscription_purchase (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id    UUID NOT NULL REFERENCES account(id) ON DELETE CASCADE,
    plan_id       SMALLINT NOT NULL REFERENCES subscription_plan(id),
    purchased_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    start_date    DATE NOT NULL,
    end_date      DATE NOT NULL,
    price_paid    NUMERIC(10,2) NOT NULL,
    CONSTRAINT chk_sub_dates CHECK (end_date >= start_date)
);
-- برای کوئری سریع «اشتراک فعال است؟»
CREATE INDEX idx_sub_purchase_account_end ON subscription_purchase(account_id, end_date DESC);

-- =====================================================================
-- 6. ژانرها (مشترک بین فیلم و مقاله)
-- =====================================================================
CREATE TABLE genre (
    id          SMALLSERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    applies_to  VARCHAR(10) NOT NULL DEFAULT 'both'  -- movie | article | both
);

-- =====================================================================
-- 7. فیلم‌ها
-- =====================================================================
CREATE TABLE movie (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title                    VARCHAR(255) NOT NULL,
    release_year             SMALLINT,
    synopsis                 TEXT,
    video_file_url           TEXT,
    imdb_rating              NUMERIC(3,1),
    imdb_link                TEXT,
    community_rating         NUMERIC(3,2),        -- کش شده از movie_rating
    uploaded_by_company_id   UUID REFERENCES company(id),
    status                   VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending|approved|rejected
    approved_by_operator_id  UUID REFERENCES employee(account_id),
    approved_at              TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_movie_status ON movie(status);

CREATE TABLE movie_genre (
    movie_id  UUID     REFERENCES movie(id) ON DELETE CASCADE,
    genre_id  SMALLINT REFERENCES genre(id) ON DELETE RESTRICT,
    PRIMARY KEY (movie_id, genre_id)
);

-- بازیگران/کارگردانان: به Person وصل می‌شود، نه Account
CREATE TABLE movie_cast (
    movie_id        UUID REFERENCES movie(id)  ON DELETE CASCADE,
    person_id       UUID REFERENCES person(id) ON DELETE RESTRICT,
    role_type       VARCHAR(20) NOT NULL,   -- actor | director | writer ...
    character_name  VARCHAR(150),
    PRIMARY KEY (movie_id, person_id, role_type)
);

CREATE TABLE movie_subtitle (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movie_id  UUID NOT NULL REFERENCES movie(id) ON DELETE CASCADE,
    language  VARCHAR(10) NOT NULL,   -- ISO 639-1
    file_url  TEXT NOT NULL
);
CREATE UNIQUE INDEX uq_movie_subtitle_lang ON movie_subtitle(movie_id, language);

CREATE TABLE movie_audio (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movie_id  UUID NOT NULL REFERENCES movie(id) ON DELETE CASCADE,
    language  VARCHAR(10) NOT NULL,
    file_url  TEXT NOT NULL
);
CREATE UNIQUE INDEX uq_movie_audio_lang ON movie_audio(movie_id, language);

-- امتیاز مردمی واقعی (هر کاربر یک امتیاز) — منبع محاسبه‌ی community_rating
CREATE TABLE movie_rating (
    account_id  UUID REFERENCES account(id) ON DELETE CASCADE,
    movie_id    UUID REFERENCES movie(id)   ON DELETE CASCADE,
    score       SMALLINT NOT NULL CHECK (score BETWEEN 1 AND 10),
    rated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (account_id, movie_id)
);

-- =====================================================================
-- 8. مقالات
-- =====================================================================
CREATE TABLE article (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title               VARCHAR(255) NOT NULL,
    body                TEXT NOT NULL,
    author_employee_id  UUID NOT NULL REFERENCES employee(account_id),
    status              VARCHAR(20) NOT NULL DEFAULT 'draft', -- draft|published|archived
    view_count          BIGINT NOT NULL DEFAULT 0,
    published_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_article_author ON article(author_employee_id);

CREATE TABLE article_genre (
    article_id  UUID     REFERENCES article(id) ON DELETE CASCADE,
    genre_id    SMALLINT REFERENCES genre(id)    ON DELETE RESTRICT,
    PRIMARY KEY (article_id, genre_id)
);

-- بازدید مقاله برای محاسبه‌ی پاداش critique
CREATE TABLE article_view (
    id          BIGSERIAL PRIMARY KEY,
    article_id  UUID NOT NULL REFERENCES article(id) ON DELETE CASCADE,
    account_id  UUID REFERENCES account(id) ON DELETE SET NULL,
    viewed_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_article_view_article ON article_view(article_id);

-- پاداش دوره‌ای critique (محاسبه‌شده از article_view، نه یک عدد خام)
CREATE TABLE critique_bonus (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id   UUID NOT NULL REFERENCES employee(account_id) ON DELETE CASCADE,
    period_start  DATE NOT NULL,
    period_end    DATE NOT NULL,
    total_views   BIGINT NOT NULL,
    bonus_amount  NUMERIC(12,2) NOT NULL,
    paid_at       TIMESTAMPTZ
);

-- =====================================================================
-- 9. کامنت‌ها — دو جدول جدا برای حفظ یکپارچگی ارجاعی (FK واقعی)
-- =====================================================================
CREATE TABLE movie_comment (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    movie_id           UUID NOT NULL REFERENCES movie(id) ON DELETE CASCADE,
    account_id         UUID NOT NULL REFERENCES account(id) ON DELETE CASCADE,
    parent_comment_id  UUID REFERENCES movie_comment(id) ON DELETE CASCADE,
    body               TEXT NOT NULL,
    is_deleted         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_movie_comment_movie  ON movie_comment(movie_id);
CREATE INDEX idx_movie_comment_parent ON movie_comment(parent_comment_id);

CREATE TABLE article_comment (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id         UUID NOT NULL REFERENCES article(id) ON DELETE CASCADE,
    account_id         UUID NOT NULL REFERENCES account(id) ON DELETE CASCADE,
    parent_comment_id  UUID REFERENCES article_comment(id) ON DELETE CASCADE,
    body               TEXT NOT NULL,
    is_deleted         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_article_comment_article ON article_comment(article_id);
CREATE INDEX idx_article_comment_parent  ON article_comment(parent_comment_id);

-- اطلاع‌رسانی پاسخ به کامنت (تا کاربر باخبر شود کسی جوابش را داده)
CREATE TABLE comment_notification (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_account_id  UUID NOT NULL REFERENCES account(id) ON DELETE CASCADE,
    source_type           VARCHAR(10) NOT NULL,  -- 'movie' | 'article'
    source_comment_id     UUID NOT NULL,
    is_read               BOOLEAN NOT NULL DEFAULT FALSE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notification_recipient ON comment_notification(recipient_account_id, is_read);

-- =====================================================================
-- 10. تاریخچه‌ی تماشا — پایه‌ی سیستم پیشنهاد (recommendation)
-- =====================================================================
CREATE TABLE watch_history (
    id             BIGSERIAL PRIMARY KEY,
    account_id     UUID NOT NULL REFERENCES account(id) ON DELETE CASCADE,
    movie_id       UUID NOT NULL REFERENCES movie(id) ON DELETE CASCADE,
    watched_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    watch_seconds  INT NOT NULL DEFAULT 0
);
CREATE INDEX idx_watch_history_account ON watch_history(account_id, watched_at DESC);
CREATE INDEX idx_watch_history_movie   ON watch_history(movie_id);
