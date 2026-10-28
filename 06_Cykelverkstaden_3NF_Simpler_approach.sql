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
-- Functional dependencies in the original export, under the assumptions above:
--
-- order_nr -> order_datum, kund_namn, kund_epost, cykel_ramnr,
--             cykel_marke, cykel_modell, mekaniker_namn,
--             mekaniker_niva, timpris, arbetstid_min
--
-- artikel_nr -> artikel_namn, leverantor, leverantor_ort
--
-- (order_nr, artikel_nr) -> antal, styckpris
--
-- Key Takeaway
-- 1NF ensures data is stored in a flat, structured format where each value is 
-- atomic and each row is unique. It is the foundation for higher normal 
-- forms (2NF, 3NF, etc.).
--
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

-- phone_number: one row per customer–phone pair. The pair (kund_epost, kund_telefon) 
-- identifies a phone record under your stated assumption; this does not imply that 
-- email uniquely identifies a customer.
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
--
-- 2NF requires a relation to be in 1NF and every non-prime attribute  to depend 
-- on the whole of each candidate key—not just part of a composite candidate key.
--
-- In the raw export, order-level attributes are repeated for each article on an 
-- order. Under the order-part key assumption (order_nr, artikel_nr):
--
--   order_nr  -> order-level attributes
--   artikel_nr -> article-level attributes
--   (order_nr, artikel_nr) -> quantity and order-specific unit price
--
-- The first two dependencies are partial dependencies on the composite key. I 
-- separate the data into work_order, part, and order_part to remove those 
-- partial dependencies.
--
-- ============================================================================


-- To continue to normalize the work_order table into 2NF, we must ensure that all non-key 
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

-- "Key" Analysis
-- key assumption for order-part rows:
-- Assume each article is listed at most once per work order. Then (order_nr, artikel_nr) 
-- identifies an order-part row.
--
-- This key assumption applies only to rows with a non-NULL artikel_nr. An order with no 
-- recorded article, such as order 1003, is still a work order, but does not have an 
-- order_part row.

-- 2NF: The original export combines order-level attributes with order-part attributes. 
-- For order-part rows, the assumed composite key is (order_nr, artikel_nr). Order-level 
-- attributes depend on order_nr alone, while article attributes depend on artikel_nr alone. 
-- These are partial dependencies on the composite key.

-- To remove them, the data is decomposed into work_order, part, and order_part. In the 
-- resulting work_order table, order_nr is the single-column primary key, so its non-key 
-- attributes depend on the whole key.

-- Functional Dependencies
-- order_nr -> order_datum, cykel_ramnr, mekaniker_namn, arbetstid_min
-- artikel_nr -> artikel_namn, leverantor, leverantor_ort
-- (order_nr, artikel_nr) -> antal, styckpris


drop table if exists part;
drop table if exists order_part;


-- One row per spare part, identified by article number.
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

-- part: one row per article; holds attributes that describe the article.
ALTER TABLE part
ADD CONSTRAINT part_pk PRIMARY KEY (artikel_nr);

-- order_part: each article can occur at most once per order.
ALTER TABLE order_part
ADD CONSTRAINT order_part_pk PRIMARY KEY (order_nr, artikel_nr);

--order_part: one row per article listed on a work order; holds order-specific quantity and unit price.
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



-- Final step is to alter the work_order table. This part is tricky.

-- work_order one row per work order; holds order-level information, including orders 
-- with no recorded article details.
-- Modify work_order to remove the article attributes
-- First, remove the columns that now belong in part or order_part:
alter table work_order
drop column artikel_nr,
drop column artikel_namn,
drop column leverantor,
drop column leverantor_ort,
drop column antal,
drop column styckpris;

-- Replace the work_order data with distinct orders
-- Run this after dropping the six article columns:
delete from work_order;
-- This preserves order 1003 even though its article fields were NULL.
insert into work_order (
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
    arbetstid_min
)
select distinct
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
    arbetstid_min
from arbetsorder_export;


-- work_order: each order number identifies one work order.
alter table work_order
add constraint work_order_pk primary key (order_nr);

-- Now we can update order_part with its other key.
alter table order_part
add constraint order_part_work_order_fk
foreign key (order_nr)
references work_order (order_nr);

-- ============================================================================
-- 3NF: Create the final normalized schema
-- ============================================================================

-- Drop the existing 2NF tables in dependency order.
-- The original arbetsorder_export table is preserved.

DROP TABLE IF EXISTS order_part;
DROP TABLE IF EXISTS phone_number;
DROP TABLE IF EXISTS work_order;
DROP TABLE IF EXISTS part;
DROP TABLE IF EXISTS mechanic;
DROP TABLE IF EXISTS mechanic_level;
DROP TABLE IF EXISTS supplier;
DROP TABLE IF EXISTS bicycle;
DROP TABLE IF EXISTS customer;


-- ============================================================================
-- 1. Create tables without foreign-key dependencies
-- ============================================================================

CREATE TABLE customer (
    kund_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kund_namn TEXT NOT NULL,
    kund_epost TEXT NOT NULL
);

CREATE TABLE bicycle (
    cykel_ramnr TEXT PRIMARY KEY,
    cykel_marke TEXT NOT NULL,
    cykel_modell TEXT NOT NULL
);

CREATE TABLE mechanic_level (
    mekaniker_niva TEXT PRIMARY KEY,
    timpris NUMERIC(8,2) NOT NULL
);

CREATE TABLE supplier (
    leverantor TEXT PRIMARY KEY,
    leverantor_ort TEXT NOT NULL
);


-- ============================================================================
-- 2. Create tables with foreign-key dependencies
-- ============================================================================

CREATE TABLE mechanic (
    mekaniker_namn TEXT PRIMARY KEY,
    mekaniker_niva TEXT NOT NULL,
    CONSTRAINT mechanic_level_fk
        FOREIGN KEY (mekaniker_niva)
        REFERENCES mechanic_level (mekaniker_niva)
);

CREATE TABLE part (
    artikel_nr TEXT PRIMARY KEY,
    artikel_namn TEXT NOT NULL,
    leverantor TEXT NOT NULL,
    CONSTRAINT part_supplier_fk
        FOREIGN KEY (leverantor)
        REFERENCES supplier (leverantor)
);

CREATE TABLE work_order (
    order_nr INTEGER PRIMARY KEY,
    order_datum DATE,
    kund_id INTEGER NOT NULL,
    cykel_ramnr TEXT NOT NULL,
    mekaniker_namn TEXT NOT NULL,
    arbetstid_min INTEGER,
    CONSTRAINT work_order_customer_fk
        FOREIGN KEY (kund_id)
        REFERENCES customer (kund_id),
    CONSTRAINT work_order_bicycle_fk
        FOREIGN KEY (cykel_ramnr)
        REFERENCES bicycle (cykel_ramnr),
    CONSTRAINT work_order_mechanic_fk
        FOREIGN KEY (mekaniker_namn)
        REFERENCES mechanic (mekaniker_namn)
);

CREATE TABLE phone_number (
    kund_id INTEGER NOT NULL,
    kund_telefon TEXT NOT NULL,
    PRIMARY KEY (kund_id, kund_telefon),
    CONSTRAINT phone_number_customer_fk
        FOREIGN KEY (kund_id)
        REFERENCES customer (kund_id)
);

CREATE TABLE order_part (
    order_nr INTEGER NOT NULL,
    artikel_nr TEXT NOT NULL,
    antal INTEGER NOT NULL,
    styckpris NUMERIC(8,2) NOT NULL,
    PRIMARY KEY (order_nr, artikel_nr),
    CONSTRAINT order_part_work_order_fk
        FOREIGN KEY (order_nr)
        REFERENCES work_order (order_nr),
    CONSTRAINT order_part_artikel_fk
        FOREIGN KEY (artikel_nr)
        REFERENCES part (artikel_nr)
);


-- ============================================================================
-- 3. Populate the tables in dependency order
-- ============================================================================

-- Customers: one row per distinct name/email combination.

INSERT INTO customer (kund_namn, kund_epost)
SELECT DISTINCT kund_namn, kund_epost
FROM arbetsorder_export;


-- Bicycles: one row per frame number.

INSERT INTO bicycle (cykel_ramnr, cykel_marke, cykel_modell)
SELECT DISTINCT cykel_ramnr, cykel_marke, cykel_modell
FROM arbetsorder_export;


-- Mechanic levels: each level determines its hourly rate.

INSERT INTO mechanic_level (mekaniker_niva, timpris)
SELECT DISTINCT mekaniker_niva, timpris
FROM arbetsorder_export;


-- Mechanics: one row per mechanic.

INSERT INTO mechanic (mekaniker_namn, mekaniker_niva)
SELECT DISTINCT mekaniker_namn, mekaniker_niva
FROM arbetsorder_export;


-- Suppliers: one row per supplier.
-- Only rows with spare-part information contribute supplier data.

INSERT INTO supplier (leverantor, leverantor_ort)
SELECT DISTINCT leverantor, leverantor_ort
FROM arbetsorder_export
WHERE artikel_nr IS NOT NULL;


-- Spare parts: supplier town is stored in supplier, not repeated here.

INSERT INTO part (artikel_nr, artikel_namn, leverantor)
SELECT DISTINCT artikel_nr, artikel_namn, leverantor
FROM arbetsorder_export
WHERE artikel_nr IS NOT NULL;


-- Work orders: one row per order, including order 1003,
-- which has no spare parts.

INSERT INTO work_order (
    order_nr,
    order_datum,
    kund_id,
    cykel_ramnr,
    mekaniker_namn,
    arbetstid_min
)
SELECT DISTINCT
    ae.order_nr,
    ae.order_datum,
    c.kund_id,
    ae.cykel_ramnr,
    ae.mekaniker_namn,
    ae.arbetstid_min
FROM arbetsorder_export AS ae
JOIN customer AS c
    ON c.kund_namn = ae.kund_namn
   AND c.kund_epost = ae.kund_epost;


-- Phone numbers: match customers by both name and email.
-- UNION removes duplicate customer/phone combinations.

INSERT INTO phone_number (kund_id, kund_telefon)
SELECT c.kund_id, ae.kund_telefon_1
FROM arbetsorder_export AS ae
JOIN customer AS c
    ON c.kund_namn = ae.kund_namn
   AND c.kund_epost = ae.kund_epost
WHERE ae.kund_telefon_1 IS NOT NULL

UNION

SELECT c.kund_id, ae.kund_telefon_2
FROM arbetsorder_export AS ae
JOIN customer AS c
    ON c.kund_namn = ae.kund_namn
   AND c.kund_epost = ae.kund_epost
WHERE ae.kund_telefon_2 IS NOT NULL;


-- Order-part records: only create rows where a spare part exists.
-- Order 1003 therefore remains in work_order without an order_part row.

INSERT INTO order_part (
    order_nr,
    artikel_nr,
    antal,
    styckpris
)
SELECT
    order_nr,
    artikel_nr,
    antal,
    styckpris
FROM arbetsorder_export
WHERE artikel_nr IS NOT NULL;

-- =============================================================================
-- Add reject constraints. 
-- ============================================================================= 

alter table work_order
add constraint work_order_arbetstid_check
check (arbetstid_min >= 0);

-- Validate the epost format and that the epost must contain "@".
alter table customer
add constraint customer_email_check
check (kund_epost LIKE '%@%');
