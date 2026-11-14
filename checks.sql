-- =====================================================
-- checks.sql — проверочные запросы
-- Отчётная дата зафиксирована: 15.11.2026, чтобы результаты
-- не менялись со временем. Для «живой» даты замените
-- '2026-11-15' на date('now').
-- =====================================================


-- 1. Кто сейчас имеет активный абонемент
SELECT m.first_name || ' ' || m.last_name AS участник,
       ms.plan_type                        AS абонемент,
       ms.end_date                         AS действует_до
FROM memberships ms
JOIN members m ON m.id = ms.member_id
WHERE '2026-11-15' BETWEEN ms.start_date AND ms.end_date
ORDER BY ms.end_date;


-- 2. Сколько людей записано на занятия по датам
SELECT date(c.start_time) AS дата,
       COUNT(b.id)        AS записей
FROM classes c
LEFT JOIN bookings b ON b.class_id = c.id
GROUP BY date(c.start_time)
ORDER BY дата;


-- 3. Список тренеров и их занятия
SELECT t.first_name || ' ' || t.last_name AS тренер,
       t.specialization                    AS специализация,
       c.name                              AS занятие,
       c.start_time                        AS начало,
       c.room                              AS зал
FROM trainers t
JOIN classes c ON c.trainer_id = t.id
ORDER BY тренер, c.start_time;


-- 4. Участники, которые давно не посещали клуб (больше 30 дней или ни разу)
SELECT m.first_name || ' ' || m.last_name AS участник,
       COALESCE(MAX(v.visit_at), 'ни разу') AS последний_визит
FROM members m
LEFT JOIN visits v ON v.member_id = m.id
GROUP BY m.id
HAVING MAX(v.visit_at) IS NULL
    OR MAX(v.visit_at) < date('2026-11-15', '-30 days')
ORDER BY последний_визит;


-- 5. Топ-3 самых популярных занятий (по числу записей)
SELECT c.name      AS занятие,
       COUNT(b.id) AS записей
FROM classes c
LEFT JOIN bookings b ON b.class_id = c.id
GROUP BY c.name
ORDER BY записей DESC, занятие
LIMIT 3;


-- 6. Сколько клуб заработал по видам абонементов
SELECT ms.plan_type    AS абонемент,
       COUNT(p.id)     AS продаж,
       SUM(p.amount)   AS выручка_руб
FROM payments p
JOIN memberships ms ON ms.id = p.membership_id
GROUP BY ms.plan_type
ORDER BY выручка_руб DESC;


-- 7. Конфликты в расписании: у одного человека пересекаются занятия
SELECT m.first_name || ' ' || m.last_name   AS участник,
       c1.name || ' (' || c1.start_time || '–' || substr(c1.end_time, 12) || ')' AS занятие_1,
       c2.name || ' (' || c2.start_time || '–' || substr(c2.end_time, 12) || ')' AS занятие_2
FROM bookings b1
JOIN bookings b2 ON b2.member_id = b1.member_id AND b2.class_id > b1.class_id
JOIN classes c1  ON c1.id = b1.class_id
JOIN classes c2  ON c2.id = b2.class_id
JOIN members m   ON m.id = b1.member_id
WHERE c1.start_time < c2.end_time
  AND c2.start_time < c1.end_time;


-- 8. Заполненность занятий: сколько мест занято из доступных
SELECT c.name || ' ' || c.start_time   AS занятие,
       COUNT(b.id) || ' из ' || c.capacity AS занято,
       CAST(ROUND(100.0 * COUNT(b.id) / c.capacity) AS INTEGER) || '%' AS заполненность
FROM classes c
LEFT JOIN bookings b ON b.class_id = c.id
GROUP BY c.id
ORDER BY 100.0 * COUNT(b.id) / c.capacity DESC;


-- 9. Абонементы, которые заканчиваются в ближайшие 14 дней
--    (кому из участников стоит напомнить о продлении)
SELECT m.first_name || ' ' || m.last_name AS участник,
       m.phone                             AS телефон,
       ms.plan_type                        AS абонемент,
       ms.end_date                         AS заканчивается
FROM memberships ms
JOIN members m ON m.id = ms.member_id
WHERE ms.end_date BETWEEN '2026-11-15' AND date('2026-11-15', '+14 days')
ORDER BY ms.end_date;
