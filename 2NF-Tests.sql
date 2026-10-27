
-- =====================================================================================
-- ================================ TESTS! =============================================
-- These are data-integrity checks on the result of the transformation from 1NF to 2NF.
-- =====================================================================================

-- Number of distinct articles
select COUNT(*) as part_rows
from part;
-- Expected for the current sample dataset: 5 distinct articles.

-- Number of order/article combinations
select COUNT(*) as order_part_rows
from order_part;
-- Expected for the current sample dataset: 8 order/article rows.

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

-- Check that no article references are missing
-- This query should return zero rows.
-- Every article in order_part must exist in part
select op.artikel_nr
from order_part op
left join part p
    on op.artikel_nr = p.artikel_nr
where p.artikel_nr is null;

-- Compare part with the source data
-- This checks that all distinct article details in the source are 
-- represented in part, in both directions. Both queries should return zero rows.

-- Source articles missing from part
(
    select distinct
        artikel_nr, artikel_namn, leverantor, leverantor_ort
    from arbetsorder_export
    where artikel_nr is not null
    except
    select
        artikel_nr, artikel_namn, leverantor, leverantor_ort
    from part
);

-- Articles in part that are not in the source
(
    select
        artikel_nr, artikel_namn, leverantor, leverantor_ort
    from part
    except
    select distinct
        artikel_nr, artikel_namn, leverantor, leverantor_ort
    from arbetsorder_export
    where artikel_nr is not null
);

-- Compare order_part with the source data
-- Again, both queries should return zero rows.

-- Source order-part rows missing from order_part
(
    select order_nr, artikel_nr, antal, styckpris
    from arbetsorder_export
    where artikel_nr is not null
	except
    select order_nr, artikel_nr, antal, styckpris
    from order_part
);

-- Order-part rows not found in the source
(
    select order_nr, artikel_nr, antal, styckpris
    from order_part
	except
    select order_nr, artikel_nr, antal, styckpris
    from arbetsorder_export
    where artikel_nr is not null
);


-- Verify that each order occurs at most once in work_order.
-- This query should return zero rows; the primary key also enforces it.
select order_nr, COUNT(*)
from work_order
group by order_nr
having COUNT(*) > 1;


-- Test the 2NF tables with the arbetsorder_export table values.

-- Reconstruct the source attributes from work_order, order_part, and part.
-- Check that every source row has a matching reconstructed row.
-- This query should return zero rows.
-- It includes orders such as 1003, where the source article fields are NULL.
SELECT
    a.order_nr,
    a.order_datum,
    a.kund_namn,
    a.kund_epost,
    a.kund_telefon_1,
    a.kund_telefon_2,
    a.cykel_ramnr,
    a.cykel_marke,
    a.cykel_modell,
    a.mekaniker_namn,
    a.mekaniker_niva,
    a.timpris,
    a.arbetstid_min,
    a.artikel_nr,
    a.artikel_namn,
    a.leverantor,
    a.leverantor_ort,
    a.antal,
    a.styckpris
FROM arbetsorder_export a
WHERE NOT EXISTS (
    SELECT 1
    FROM work_order w
    LEFT JOIN order_part op
        ON op.order_nr = w.order_nr
    LEFT JOIN part p
        ON p.artikel_nr = op.artikel_nr
    WHERE w.order_nr = a.order_nr
      AND w.order_datum IS NOT DISTINCT FROM a.order_datum
      AND w.kund_namn IS NOT DISTINCT FROM a.kund_namn
      AND w.kund_epost IS NOT DISTINCT FROM a.kund_epost
      AND w.cykel_ramnr IS NOT DISTINCT FROM a.cykel_ramnr
      AND w.cykel_marke IS NOT DISTINCT FROM a.cykel_marke
      AND w.cykel_modell IS NOT DISTINCT FROM a.cykel_modell
      AND w.mekaniker_namn IS NOT DISTINCT FROM a.mekaniker_namn
      AND w.mekaniker_niva IS NOT DISTINCT FROM a.mekaniker_niva
      AND w.timpris IS NOT DISTINCT FROM a.timpris
      AND w.arbetstid_min IS NOT DISTINCT FROM a.arbetstid_min
      AND op.artikel_nr IS NOT DISTINCT FROM a.artikel_nr
      AND p.artikel_namn IS NOT DISTINCT FROM a.artikel_namn
      AND p.leverantor IS NOT DISTINCT FROM a.leverantor
      AND p.leverantor_ort IS NOT DISTINCT FROM a.leverantor_ort
      AND op.antal IS NOT DISTINCT FROM a.antal
      AND op.styckpris IS NOT DISTINCT FROM a.styckpris
);
-- This checks the order and article attributes, including rows such as order 
-- 1003 where the article fields are NULL.

-- 2. Test the phone numbers separately
-- Your phone numbers live in phone_number, so they need their own comparison. 
-- This query should also return zero rows.

-- Original phone-number pairs missing from phone_number.
-- This query should return zero rows.
(
    SELECT kund_epost, kund_telefon_1 AS kund_telefon
    FROM arbetsorder_export
    WHERE kund_telefon_1 IS NOT NULL
    UNION
    SELECT kund_epost, kund_telefon_2 AS kund_telefon
    FROM arbetsorder_export
    WHERE kund_telefon_2 IS NOT NULL
)
EXCEPT
SELECT kund_epost, kund_telefon
FROM phone_number;

-- Phone-number pairs in phone_number that do not occur in the source.
-- This query should return zero rows.
SELECT kund_epost, kund_telefon
FROM phone_number
EXCEPT
(
    SELECT kund_epost, kund_telefon_1 AS kund_telefon
    FROM arbetsorder_export
    WHERE kund_telefon_1 IS NOT NULL
    UNION
    SELECT kund_epost, kund_telefon_2 AS kund_telefon
    FROM arbetsorder_export
    WHERE kund_telefon_2 IS NOT NULL
);
