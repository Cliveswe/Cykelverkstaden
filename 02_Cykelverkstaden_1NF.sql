-- CREATE DATABASE verkstaddb;

-- ============================================================================
-- Drop and reset the schema, gives me a clean slate: 
-- drop everything → recreate raw table → reload the 9 rows.
-- Now I can experiment with SQL and NF.
-- ============================================================================
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- =========================== 1NF ============================================
-- A general rule for tables in a database.
-- The table arbetsorder_export has a ”messy semantics” which makes difficult 
-- to understand exactly what it means (difficult to understand its purpose).
-- Thus when it comes to tables, each table should describe a type of thing, 
-- each row in the table should contain data about a single such thing, and 
-- the data we stored for each thing should be in a single row. In other words, 
-- one type of thing per table, one thing per row, and one row per thing.
-- 
-- ============================================================================
-- 
-- We shall now normalise the table arbetsorder_export to satisfy the 1NF criteria.
-- 
-- 1. Atomic Columns (Indivisible Values) ✓ there is no comma-seperated lists.
-- 2. Eliminate Repeating Groups kund_telefon_1 and kund_telefon_2 violate this test.
-- 3. Unique Rows (No Duplicate Rows)
--
-- Key Takeaway
-- 1NF ensures data is stored in a flat, structured format where each value is 
-- atomic and each row is unique. It is the foundation for higher normal 
-- forms (2NF, 3NF, etc.).
--
-- I have identified 2 candidate keys for the arbetsorder-export table.
-- K1 = {order_nr, artikel_nr, styckpris}
-- K2 = {order_nr, artikel_nr, mekaniker_namn}
-- ============================================================================

DROP TABLE IF EXISTS arbetsorder_export;

CREATE TABLE arbetsorder_export (
    order_nr        integer,
    order_datum     date,
    kund_namn       text,
    kund_epost      text,
    kund_telefon_1  text,
    kund_telefon_2  text,           -- kunden har högst två nummer; tom om kunden bara har ett
    cykel_ramnr     text,
    cykel_marke     text,
    cykel_modell    text,
    mekaniker_namn  text,
    mekaniker_niva  text,           -- 'Junior' eller 'Senior'
    timpris         numeric(8,2),   -- kr per timme, beror på nivån
    arbetstid_min   integer,        -- total arbetstid för ordern
    artikel_nr      text,
    artikel_namn    text,
    leverantor      text,
    leverantor_ort  text,
    antal           integer,
    styckpris       numeric(8,2)    -- pris per styck vid den här ordern
);

INSERT INTO arbetsorder_export VALUES
-- order 1001: Maria, Crescent Elina 3, mekaniker Oskar
(1001, '2026-09-14', 'Maria Lindqvist', 'maria.lindqvist@example.com', '070-111 22 33', '073-444 55 66',
 'WSBC-4411', 'Crescent', 'Elina 3', 'Oskar Nyberg', 'Senior', 650.00, 90,
 'KE-100', 'Kedja KMC X9',             'Cykelgrossisten AB', 'Borås',  1, 249.00),
(1001, '2026-09-14', 'Maria Lindqvist', 'maria.lindqvist@example.com', '070-111 22 33', '073-444 55 66',
 'WSBC-4411', 'Crescent', 'Elina 3', 'Oskar Nyberg', 'Senior', 650.00, 90,
 'BR-210', 'Bromsbelägg Shimano',      'Cykelgrossisten AB', 'Borås',  2,  89.00),
-- order 1002: Karim, Kronan Cargo 5, mekaniker Sara
(1002, '2026-09-15', 'Karim Haddad', 'karim.haddad@example.com', '076-222 33 44', NULL,
 'XT-90210', 'Kronan', 'Cargo 5', 'Sara Ekström', 'Junior', 480.00, 45,
 'SL-280', 'Innerslang 28"',           'Däckdepån AB',       'Örebro', 1,  79.00),
-- order 1003: Maria igen, en annan cykel, bara arbete (inga delar)
(1003, '2026-09-18', 'Maria Lindqvist', 'maria.lindqvist@example.com', '070-111 22 33', '073-444 55 66',
 'WSBC-5520', 'Crescent', 'Suzy 2', 'Oskar Nyberg', 'Senior', 650.00, 30,
 NULL, NULL, NULL, NULL, NULL, NULL),
-- order 1004: Johan, Bianchi Impulso, mekaniker Sara
(1004, '2026-09-21', 'Johan Pettersson', 'johan.pettersson@example.com', '070-555 66 77', NULL,
 'GT-77123', 'Bianchi', 'Impulso', 'Sara Ekström', 'Junior', 480.00, 120,
 'DA-281', 'Däck Schwalbe Marathon 28"', 'Däckdepån AB',     'Örebro', 2, 349.00),
(1004, '2026-09-21', 'Johan Pettersson', 'johan.pettersson@example.com', '070-555 66 77', NULL,
 'GT-77123', 'Bianchi', 'Impulso', 'Sara Ekström', 'Junior', 480.00, 120,
 'SL-280', 'Innerslang 28"',           'Däckdepån AB',       'Örebro', 2,  79.00),
(1004, '2026-09-21', 'Johan Pettersson', 'johan.pettersson@example.com', '070-555 66 77', NULL,
 'GT-77123', 'Bianchi', 'Impulso', 'Sara Ekström', 'Junior', 480.00, 120,
 'BR-210', 'Bromsbelägg Shimano',      'Cykelgrossisten AB', 'Borås',  1,  89.00),
-- order 1005: Karim igen, samma cykel — kedjan har blivit dyrare
(1005, '2026-09-24', 'Karim Haddad', 'karim.haddad@example.com', '076-222 33 44', NULL,
 'XT-90210', 'Kronan', 'Cargo 5', 'Oskar Nyberg', 'Senior', 650.00, 60,
 'KE-100', 'Kedja KMC X9',             'Cykelgrossisten AB', 'Borås',  1, 259.00),
(1005, '2026-09-24', 'Karim Haddad', 'karim.haddad@example.com', '076-222 33 44', NULL,
 'XT-90210', 'Kronan', 'Cargo 5', 'Oskar Nyberg', 'Senior', 650.00, 60,
 'OL-100', 'Kedjeolja 100 ml',         'Cykelgrossisten AB', 'Borås',  1,  69.00);

-- Kontroll: ska ge 9 rader och 5 ordrar
--SELECT count(*) AS rader, count(DISTINCT order_nr) AS ordrar FROM arbetsorder_export;

-- TESTS!
-- Check for Non-Atomic Values in Text Columns.
SELECT *
FROM public.arbetsorder_export
WHERE 
  kund_namn LIKE '%,%' OR
  kund_epost LIKE '%,%' OR
  kund_telefon_1 LIKE '%,%' OR
  kund_telefon_2 LIKE '%,%' OR
  cykel_ramnr LIKE '%,%' OR
  cykel_marke LIKE '%,%' OR
  cykel_modell LIKE '%,%' OR
  mekaniker_namn LIKE '%,%' OR
  mekaniker_niva LIKE '%,%' OR
  artikel_nr LIKE '%,%' OR
  artikel_namn LIKE '%,%' OR
  leverantor LIKE '%,%' OR
  leverantor_ort LIKE '%,%';

SELECT
    column_name,
    data_type,
    udt_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'arbetsorder_export'
  AND data_type = 'ARRAY';

-- Test: Inspect the table's column names and ask whether several columns are numbered versions of the same attribute.
SELECT
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'arbetsorder_export'
ORDER BY ordinal_position;

-- Test: To identify its candidate keys, we need to determine what one row represents
-- Test if order_nr is a key.
-- If this returns rows, an order number occurs more than once. That rules out order_nr as the key for the entire export table.
SELECT
    order_nr,
    COUNT(*) AS antal_rader
FROM arbetsorder_export
GROUP BY order_nr
HAVING COUNT(*) > 1
ORDER BY antal_rader DESC;

-- Test if artikel_nr is a key.
-- If this returns rows, an order number occurs more than once. That rules out artikel_nr as the key for the entire export table.
SELECT
    artikel_nr,
    COUNT(*) AS antal_rader
FROM arbetsorder_export
GROUP BY artikel_nr 
HAVING COUNT(*) > 1
ORDER BY antal_rader DESC;

-- Test if order_nr and artikel_nr is a key.
-- If this returns rows, an order number occurs more than once. That rules out order_nr and artikel_nr as the key for the entire export table.
SELECT
    order_nr, artikel_nr,
    COUNT(*) AS antal_rader
FROM arbetsorder_export
GROUP BY order_nr, artikel_nr 
HAVING COUNT(*) > 1
ORDER BY antal_rader DESC;

-- Check that both columns are non-null: Fail because artikel_nr is null in the database for order_nr 1003.
SELECT COUNT(*) AS rader_med_saknad_nyckeldel
FROM arbetsorder_export
WHERE order_nr IS NULL
   OR artikel_nr IS NULL;

-- Test if order_nr, artikel_nr and styckpris is a key.
-- If this returns rows, an order number occurs more than once. That rules out order_nr, artikel_nr and styckpris as the key for the entire export table.
SELECT
    order_nr,
    artikel_nr,
    styckpris,
    COUNT(*) AS antal_rader
FROM arbetsorder_export
GROUP BY order_nr, artikel_nr, styckpris
HAVING COUNT(*) > 1
ORDER BY antal_rader DESC;

-- Test if order_nr, artikel_nr and mekaniker_namn is a key.
-- If this returns rows, an order number occurs more than once. That rules out order_nr, artikel_nr and mekaniker_namn as the key for the entire export table.
SELECT
    order_nr,
    artikel_nr,
    mekaniker_namn,
    COUNT(*) AS antal_rader
FROM arbetsorder_export
GROUP BY order_nr, artikel_nr, mekaniker_namn
HAVING COUNT(*) > 1
ORDER BY antal_rader DESC;

-- Test whether the arbetsorder_export has duplicate rows
-- This query identifies rows that are identical across all 19 attributes
SELECT
    order_nr,
    order_datum,
    kund_namn,
    kund_epost,
    kund_telefon_1,
    kund_telefon_2,
    cykel_ramnr,
    cykel_marke,
    cykel_modell,
    mekaniker_namn,
    mekaniker_niva,
    timpris,
    arbetstid_min,
    artikel_nr,
    artikel_namn,
    leverantor,
    leverantor_ort,
    antal,
    styckpris,
    COUNT(*) AS antal_identiska
FROM arbetsorder_export
GROUP BY
    order_nr,
    order_datum,
    kund_namn,
    kund_epost,
    kund_telefon_1,
    kund_telefon_2,
    cykel_ramnr,
    cykel_marke,
    cykel_modell,
    mekaniker_namn,
    mekaniker_niva,
    timpris,
    arbetstid_min,
    artikel_nr,
    artikel_namn,
    leverantor,
    leverantor_ort,
    antal,
    styckpris
HAVING COUNT(*) > 1;