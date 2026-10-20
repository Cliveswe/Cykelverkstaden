-- Kontroll: ska ge 9 rader och 5 ordrar
SELECT count(*) AS rader, count(DISTINCT order_nr) AS ordrar FROM arbetsorder_export;


-- =====================================================================================
-- ============================ 1NF TESTS! =============================================
-- =====================================================================================

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

-- =====================================================================================
-- ===================== Test the decompositions =======================================
-- =====================================================================================

-- Rows in the original table missing from work_order
-- Both queries should return zero rows if the data matches.
select
    order_nr, order_datum, kund_namn, kund_epost,
    cykel_ramnr, cykel_marke, cykel_modell,
    mekaniker_namn, mekaniker_niva, timpris,
    arbetstid_min, artikel_nr, artikel_namn,
    leverantor, leverantor_ort, antal, styckpris
from  arbetsorder_export
except
select
    order_nr, order_datum, kund_namn, kund_epost,
    cykel_ramnr, cykel_marke, cykel_modell,
    mekaniker_namn, mekaniker_niva, timpris,
    arbetstid_min, artikel_nr, artikel_namn,
    leverantor, leverantor_ort, antal, styckpris
from work_order;

-- Rows in work_order that are not in the original table
select
    order_nr, order_datum, kund_namn, kund_epost,
    cykel_ramnr, cykel_marke, cykel_modell,
    mekaniker_namn, mekaniker_niva, timpris,
    arbetstid_min, artikel_nr, artikel_namn,
    leverantor, leverantor_ort, antal, styckpris
from work_order
except -- compares distinct rows
select
    order_nr, order_datum, kund_namn, kund_epost,
    cykel_ramnr, cykel_marke, cykel_modell,
    mekaniker_namn, mekaniker_niva, timpris,
    arbetstid_min, artikel_nr, artikel_namn,
    leverantor, leverantor_ort, antal, styckpris
from arbetsorder_export;

-- Both queries should return zero rows
-- Phone numbers in the original table missing from phone_number
select 
	kund_epost, kund_telefon_1 as kund_telefon
from arbetsorder_export
where kund_telefon_1 is not null
union
select 
	kund_epost, kund_telefon_2 as kund_telefon
from arbetsorder_export
where kund_telefon_2 is not null
except -- compares distinct rows
select 
	kund_epost, kund_telefon
from phone_number;

-- Phone-number pairs in phone_number that are not in the original table
select
	kund_epost, kund_telefon
from phone_number
except
( 	-- PostgreSQL evaluates UNION and EXCEPT left to right, 
	-- so the query needs parentheses to compare against the 
	-- combined set of phone numbers in the original table.
	select
		kund_epost, kund_telefon_1
	from arbetsorder_export
	where kund_telefon_1 IS NOT NULL
	union 
	select 
		kund_epost, kund_telefon_2
	from arbetsorder_export
	where kund_telefon_2 IS NOT null
);

