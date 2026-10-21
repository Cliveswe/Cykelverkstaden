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




-- ============================================================================
--
-- Decomposing the relation arbetsorder_export to satisfy 1NF
--
-- ============================================================================

-- Create a phone-number relation. We can now store more than 1 telephone 
-- number per customer without adding additional columns.

drop table if exists phone_number;

-- stores one phone number per row.
create table phone_number(
	kund_epost text,
	kund_telefon text  -- kunden har högst två nummer; tom om kunden bara har ett
);

insert into phone_number (kund_epost, kund_telefon)
select kund_epost, kund_telefon_1 -- insert only if it is not null
from arbetsorder_export 
where kund_telefon_1 is not null
union -- UNION removes duplicate kund_epost/kund_telefon pairs.
select kund_epost, kund_telefon_2 -- insert only if it is not null
from arbetsorder_export
where kund_telefon_2 is not null;

-- Create a work-order relation. It is similar to the arbetsorder_export table 
-- but without the telephone attributes.
drop table if exists work_order;

-- retains the other attributes, including the article columns.
create table work_order(
	order_nr        integer,
    order_datum     date,
    kund_namn       text,
    kund_epost      text,
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

insert into work_order
select  
	order_nr,
	order_datum,
    kund_namn,
    kund_epost,
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
    styckpris from arbetsorder_export;



-- =========================== 2NF ============================================
-- A general rule for tables in a database.
-- The table arbetsorder_export has a ”messy semantics” which makes difficult 
-- to understand exactly what it means (difficult to understand its purpose).
-- Thus when it comes to tables, each table should describe a type of thing, 
-- each row in the table should contain data about a single such thing, and 
-- the data we stored for each thing should be in a single row. In other words, 
-- one type of thing per table, one thing per row, and one row per thing.
-- 
-- ============================================================================
-- We shall now normalise the table arbetsorder_export to satisfy the 2NF criteria.
-- The second normal form states that a table, in addition to being in the 
-- first normal form, may not contain any complete functional depending on parts 
-- of the primary key.

-- ============================================================================


-- To normalize the work_order table into 2NF, we must ensure that all non-key 
-- attributes are fully functionally dependent on the primary key (no partial dependencies). 
-- Based on the schema provided, here's the analysis and normalization steps:
--
-- 1. Identify the Primary Key
-- The table work_order lacks an explicit PRIMARY KEY constraint, thus we must make an
-- Assumption: Within a the relation work_order, each spare-part article is recorded at most 
-- once. Therefore, for rows representing order-part lines, (order_nr, artikel_nr) is the 
-- minimal key and since it is the only key it is the primary key.
-- 2. Check for Partial Dependencies
-- Partial dependencies occur when a non-key attribute depends on only part of a 
-- composite primary key. 


-- Since order_nr is a single-column key, there are no partial 
-- dependencies by definition. However, we must verify if any non-key attributes depend on other columns (e.g., cykel_ramnr, artikel_nr).

-- Candidate Key Analysis
-- The table lacks an explicit PRIMARY KEY constraint, but we make an assumption
-- that (order_nr, artikel_nr) is a likely candidate key.
 
-- Functional Dependencies
-- order_nr -> order_datum, cykel_ramnr, mekaniker_namn, arbetstid_min
-- artikel_nr -> artikel_namn, leverantor, leverantor_ort
-- (order_nr, artikel_nr) -> antal, styckpris


drop table if exists part;
drop table if exists order_part;


-- One row per spar-part by article.
create table part(
	artikel_nr      text,
    artikel_namn    text,
    leverantor      text,
    leverantor_ort  text
);

-- One row per article recorded on a work order.
create table order_part(
	order_nr        integer,
	artikel_nr      text,
	antal           integer,
    styckpris       numeric(8,2)    -- pris per styck vid den här ordern
);


-- ============================================================================
-- Modify tables to satisfy 2NF
-- ============================================================================

-- part: each article number identifies one article.
ALTER TABLE part
ADD CONSTRAINT part_pk PRIMARY KEY (artikel_nr);

-- order_part: each article can occur at most once per order.
ALTER TABLE order_part
ADD CONSTRAINT order_part_pk PRIMARY KEY (order_nr, artikel_nr);

ALTER TABLE order_part
ADD CONSTRAINT order_part_artikel_fk
FOREIGN KEY (artikel_nr)
REFERENCES part (artikel_nr);

-- Insert article details, once per article.
insert into part (
    artikel_nr,
    artikel_namn,
    leverantor,
    leverantor_ort
)
select distinct 
    artikel_nr,
    artikel_namn,
    leverantor,
    leverantor_ort
from arbetsorder_export
where artikel_nr is not null;

-- Insert order/article details.
insert into order_part (
    order_nr,
    artikel_nr,
    antal,
    styckpris
)
select 
    order_nr,
    artikel_nr,
    antal,
    styckpris
from arbetsorder_export
where artikel_nr is not null;

-- Tests.
-- Number of distinct articles
select COUNT(*) as part_rows
from part;

-- Expected: 5

-- Number of order/article combinations
select COUNT(*) as order_part_rows
from order_part;

-- Expected: 8

-- No duplicate article numbers in part
select artikel_nr, COUNT(*)
from part
group by artikel_nr
having COUNT(*) > 1;

-- No duplicate order/article combinations
select order_nr, artikel_nr, COUNT(*)
from order_part
group by order_nr, artikel_nr
having COUNT(*) > 1;
