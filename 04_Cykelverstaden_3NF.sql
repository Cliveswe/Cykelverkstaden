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
-- Modify tables to satisfy 3NF
-- ============================================================================

/*
  	Step 1 identify transitive dependencies.

	In work_order, order_nr is the primary key and determines all other attributes.

	The business rules suggest these additional dependencies:

    cykel_ramnr -> cykel_marke, cykel_modell

    mekaniker_namn -> mekaniker_niva
    mekaniker_niva -> timpris

	These dependencies suggest that bicycle and mechanic information may be stored 
	in separate relations.

	In part, investigate:

    artikel_nr -> leverantor
    leverantor -> leverantor_ort

	If these dependencies hold, bicycle, mechanic and supplier attributes may be 
	transitively dependent on the primary key of their current relation.


	Step 2: Decompose work_order

	BICYCLE
	------
	The dependency

    cykel_ramnr -> cykel_marke, cykel_modell

	shows that bicycle brand and model depend on the frame number rather than directly on 
	the work order.

	Create a bicycle relation with cykel_ramnr as its key.

	MECHANIC
	--------
	The dependencies

    mekaniker_namn -> mekaniker_niva
    mekaniker_niva -> timpris

	show that mechanic level and hourly rate are not independent work_order attributes.

	Create separate mechanic and mechanic_level relations.

	Provisional assumption:
	mekaniker_namn uniquely identifies a mechanic.
	This will be reviewed when deciding on final keys.


	3NF - Step 3: Decompose part
	The current part relation contains:

    artikel_nr
    artikel_namn
    leverantor
    leverantor_ort

	Functional dependencies:

    artikel_nr -> artikel_namn, leverantor, leverantor_ort
    leverantor -> leverantor_ort

	Assuming each supplier has one town, leverantor_ort depends transitively on artikel_nr 
	through leverantor.

	Decompose into:

    part(artikel_nr, artikel_namn, leverantor)

    supplier(leverantor, leverantor_ort)

	Provisional assumption:
	leverantor uniquely identifies a supplier, and each supplier has one town.


	Step 4: Review customer and phone-number relations

	Customer attributes currently stored in work_order:

    kund_namn
    kund_epost

	Phone numbers are stored separately in:

    phone_number(kund_epost, kund_telefon)

	The assignment allows a customer to have multiple phone numbers, so storing phone 
	numbers in separate rows avoids the original repeating phone columns.

	However, the assignment does not state that kund_epost uniquely identifies a customer.

	Therefore, the dependency

    kund_epost -> kund_namn

	cannot be assumed without an explicit design assumption.

	Possible future design:
	Introduce a customer relation with a customer_id primary key, and reference that key 
	from work_order and phone_number.

	The final customer key and foreign keys will be decided during constraint design.


	Step 5: Consolidate functional dependencies

WORK_ORDER
    order_nr -> order_datum, kund_namn, kund_epost,
                cykel_ramnr, mekaniker_namn, arbetstid_min

BICYCLE
    cykel_ramnr -> cykel_marke, cykel_modell

MECHANIC
    mekaniker_namn -> mekaniker_niva
    (assuming mechanic names uniquely identify mechanics)

MECHANIC_LEVEL
    mekaniker_niva -> timpris

PART
    artikel_nr -> artikel_namn, leverantor

SUPPLIER
    leverantor -> leverantor_ort
    (assuming each supplier has one town and supplier
     names uniquely identify suppliers)

ORDER_PART
    (order_nr, artikel_nr) -> antal, styckpris
    (assuming each part occurs at most once per order)

CUSTOMER / PHONE_NUMBER
    Customer identification and phone-number key remain
    unresolved because the assignment does not establish
    that kund_epost uniquely identifies a customer.

Step 6: Introduce a customer surrogate key

Design decision:
Introduce kund_id as the primary key of customer.

Reason:
The assignment does not state that kund_epost is unique or that every customer 
must have an email address. Therefore, email is not assumed to identify a customer.

Proposed relation:

    customer(
        kund_id,
        kund_namn,
        kund_epost
    )

Functional dependency:

    kund_id -> kund_namn, kund_epost

Relationship changes:
- work_order will reference customer using kund_id.
- phone_number will reference customer using kund_id.

This avoids relying on email as a customer identifier.

The existing data must be mapped to kund_id during migration so that work orders 
and phone numbers remain associated with the correct customers.


Step 7: Consolidate keys and relationships

Primary keys:
- customer: kund_id
- phone_number: (kund_id, kund_telefon)
- work_order: order_nr
- bicycle: cykel_ramnr
- mechanic: mekaniker_namn (provisional)
- mechanic_level: mekaniker_niva
- part: artikel_nr
- supplier: leverantor (provisional)
- order_part: (order_nr, artikel_nr)

Foreign keys connect:
- phone_number to customer
- work_order to customer, bicycle and mechanic
- mechanic to mechanic_level
- part to supplier
- order_part to work_order and part

The design assumes mechanic names and supplier names uniquely identify their 
respective entities.

The composite keys for phone_number and order_part assume duplicate entries are 
not permitted for the same customer/phone or order/part combination.

These assumptions must be checked against the source data and business rules 
before constraints are added.

 Data completeness and NULL handling

In arbetsorder_export, NULL means that data was not
available in the source export. It does not, by itself,
define whether an attribute is nullable in the final schema.

The source only permits NULL in:
- kund_telefon_2
- artikel_nr
- artikel_namn
- leverantor
- leverantor_ort
- antal
- styckpris

During normalization:
- Missing second phone numbers are represented by the absence of a phone_number row.
- Rows without available part information do not create order_part entries.
- Work order 1003 must remain in work_order.
- NOT NULL constraints are decided from the intended business rules and final relation design.

Missing source information must not be interpreted as proof that the corresponding 
business attribute is optional.

*/

-- Create the 3NF tables.
-- These are new tables. The existing 2NF tables remain unchanged.
-- Primary keys and required columns are defined now.

DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS bicycle;
DROP TABLE IF EXISTS mechanic_level;
DROP TABLE IF EXISTS mechanic;
DROP TABLE IF EXISTS supplier;

-- A customer receives a generated ID because the assignment does not establish 
-- that email addresses are unique identifiers.
CREATE TABLE customer (
    kund_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kund_namn text NOT NULL,
    kund_epost text NOT NULL
);

-- A bicycle is identified by its unique frame number. Brand and model depend on that frame number.
CREATE TABLE bicycle (
    cykel_ramnr text PRIMARY KEY,
    cykel_marke text NOT NULL,
    cykel_modell text NOT NULL
);

-- The mechanic's level is stored separately from the hourly rate because the assignment 
-- states that the level determines the rate.
CREATE TABLE mechanic_level (
    mekaniker_niva text PRIMARY KEY,
    timpris numeric(8,2) NOT NULL
);

-- Mechanic names are being used as identifiers for now. This assumes that two
-- different mechanics cannot share a name.
CREATE TABLE mechanic (
    mekaniker_namn text PRIMARY KEY,
    mekaniker_niva text NOT NULL
);

-- Each supplier is assumed to have one town.
CREATE TABLE supplier (
    leverantor text PRIMARY KEY,
    leverantor_ort text NOT NULL
);


