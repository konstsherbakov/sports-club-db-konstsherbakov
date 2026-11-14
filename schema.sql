-- =====================================================
-- schema.sql — структура базы данных «Спортивный клуб»
-- СУБД: SQLite
-- =====================================================

-- Включаем проверку внешних ключей (в SQLite по умолчанию выключена)
PRAGMA foreign_keys = ON;

-- Удаляем таблицы, если они уже есть, чтобы скрипт можно было запускать повторно.
-- Порядок обратный созданию: сначала зависимые таблицы, потом основные.
DROP TABLE IF EXISTS visits;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS memberships;
DROP TABLE IF EXISTS trainers;
DROP TABLE IF EXISTS members;

-- -----------------------------------------------------
-- members — участники клуба
-- -----------------------------------------------------
CREATE TABLE members (
    id          INTEGER PRIMARY KEY,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,              -- e-mail не может повторяться
    phone       TEXT,
    birth_date  TEXT NOT NULL,                     -- формат ГГГГ-ММ-ДД
    join_date   TEXT NOT NULL,
    -- CHECK 1: на момент вступления участнику не меньше 14 лет
    CHECK (birth_date <= date(join_date, '-14 years'))
);

-- -----------------------------------------------------
-- trainers — тренеры
-- -----------------------------------------------------
CREATE TABLE trainers (
    id              INTEGER PRIMARY KEY,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    specialization  TEXT NOT NULL,
    hire_date       TEXT NOT NULL
);

-- -----------------------------------------------------
-- memberships — абонементы участников
-- Связь: один участник → много абонементов (покупает их повторно)
-- -----------------------------------------------------
CREATE TABLE memberships (
    id          INTEGER PRIMARY KEY,
    member_id   INTEGER NOT NULL,
    plan_type   TEXT NOT NULL,
    price       REAL NOT NULL,
    start_date  TEXT NOT NULL,
    end_date    TEXT NOT NULL,
    -- CHECK 2: только три вида абонементов
    CHECK (plan_type IN ('Месячный', 'Квартальный', 'Годовой')),
    -- CHECK 3: цена положительная
    CHECK (price > 0),
    -- CHECK 4: абонемент заканчивается позже, чем начинается
    CHECK (end_date > start_date),
    FOREIGN KEY (member_id) REFERENCES members(id)
);

-- -----------------------------------------------------
-- payments — оплаты абонементов
-- Связь: один абонемент → одна или несколько оплат (например, рассрочка)
-- -----------------------------------------------------
CREATE TABLE payments (
    id             INTEGER PRIMARY KEY,
    membership_id  INTEGER NOT NULL,
    amount         REAL NOT NULL,
    paid_at        TEXT NOT NULL,
    method         TEXT NOT NULL,
    -- CHECK 5: сумма оплаты положительная
    CHECK (amount > 0),
    -- CHECK 6: допустимые способы оплаты
    CHECK (method IN ('card', 'cash', 'transfer')),
    FOREIGN KEY (membership_id) REFERENCES memberships(id)
);

-- -----------------------------------------------------
-- classes — занятия в расписании (конкретное время и зал)
-- Связь: один тренер → много занятий
-- -----------------------------------------------------
CREATE TABLE classes (
    id          INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    trainer_id  INTEGER NOT NULL,
    start_time  TEXT NOT NULL,                     -- формат ГГГГ-ММ-ДД ЧЧ:ММ
    end_time    TEXT NOT NULL,
    capacity    INTEGER NOT NULL,
    room        TEXT NOT NULL,
    -- CHECK 7: количество мест в группе больше 0
    CHECK (capacity > 0),
    -- CHECK 8: занятие заканчивается позже, чем начинается
    CHECK (end_time > start_time),
    FOREIGN KEY (trainer_id) REFERENCES trainers(id)
);

-- -----------------------------------------------------
-- bookings — записи участников на занятия
-- Связь «многие ко многим» между members и classes:
-- участник ходит на много занятий, на занятии много участников
-- -----------------------------------------------------
CREATE TABLE bookings (
    id          INTEGER PRIMARY KEY,
    member_id   INTEGER NOT NULL,
    class_id    INTEGER NOT NULL,
    booked_at   TEXT NOT NULL,
    -- нельзя дважды записаться на одно и то же занятие
    UNIQUE (member_id, class_id),
    FOREIGN KEY (member_id) REFERENCES members(id),
    FOREIGN KEY (class_id) REFERENCES classes(id)
);

-- -----------------------------------------------------
-- visits — посещения клуба (отметка на входе)
-- Связь: один участник → много посещений
-- -----------------------------------------------------
CREATE TABLE visits (
    id          INTEGER PRIMARY KEY,
    member_id   INTEGER NOT NULL,
    visit_at    TEXT NOT NULL,
    FOREIGN KEY (member_id) REFERENCES members(id)
);

-- -----------------------------------------------------
-- Индексы — ускорители поиска по часто используемым полям
-- -----------------------------------------------------
CREATE INDEX idx_memberships_member   ON memberships (member_id);
CREATE INDEX idx_classes_start        ON classes (start_time);
CREATE INDEX idx_bookings_class       ON bookings (class_id);
CREATE INDEX idx_visits_member_date   ON visits (member_id, visit_at);
