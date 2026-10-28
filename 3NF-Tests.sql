
-- =====================================================================================
-- ============================ 3NF TESTS! =============================================
-- =====================================================================================


-- ====================================================================
-- Integrity checks.
-- ====================================================================
-- Check all work orders. Expected: 5 work orders, including order 1003.
select *
from work_order
order by order_nr;

-- Check that every work order has a valid customer, bicycle, and mechanic.
-- Expected: 5 rows. This also confirms that the mechanic's hourly rate is 
-- obtained through mechanic → mechanic_level, rather than stored 
-- redundantly in work_order.
select
    wo.order_nr,
    c.kund_namn,
    b.cykel_ramnr,
    m.mekaniker_namn,
    ml.mekaniker_niva,
    ml.timpris
from work_order as wo
join customer as c
    on wo.kund_id = c.kund_id
join bicycle as b
    on wo.cykel_ramnr = b.cykel_ramnr
join mechanic as m
    on wo.mekaniker_namn = m.mekaniker_namn
join mechanic_level as ml
    on m.mekaniker_niva = ml.mekaniker_niva
order by wo.order_nr;

-- Check spare parts and suppliers. Expected: 5 spare parts, each linked 
-- to a supplier and supplier town.
select
    p.artikel_nr,
    p.artikel_namn,
    p.leverantor,
    s.leverantor_ort
from part as p
join supplier as s
    on p.leverantor = s.leverantor
order by p.artikel_nr;

-- Check order-part records. Expected: 8 order-part records. Order 1003 
-- should have no records in order_part; that is correct because it has 
-- no recorded spare parts. 
select
    op.order_nr,
    op.artikel_nr,
    op.antal,
    op.styckpris
from order_part as op
order by op.order_nr, op.artikel_nr;

-- Confirm that no work orders or order-part rows are orphaned.
-- Must return zero rows.
select
    op.order_nr,
    op.artikel_nr
from order_part AS op
left join work_order AS wo
    on op.order_nr = wo.order_nr
left join part AS p
    on op.artikel_nr = p.artikel_nr
where wo.order_nr is null
   or p.artikel_nr is null;

-- Verify the 3NF decomposition by joining the normalized tables to 
-- reconstruct the original spreadsheet data. The query below should 
-- return 9 rows, matching arbetsorder_export, without including phone numbers.
SELECT
    wo.order_nr,
    wo.order_datum,
    c.kund_namn,
    c.kund_epost,
    b.cykel_ramnr,
    b.cykel_marke,
    b.cykel_modell,
    m.mekaniker_namn,
    m.mekaniker_niva,
    ml.timpris,
    wo.arbetstid_min,
    p.artikel_nr,
    p.artikel_namn,
    s.leverantor,
    s.leverantor_ort,
    op.antal,
    op.styckpris
FROM work_order AS wo
JOIN customer AS c
    ON wo.kund_id = c.kund_id
JOIN bicycle AS b
    ON wo.cykel_ramnr = b.cykel_ramnr
JOIN mechanic AS m
    ON wo.mekaniker_namn = m.mekaniker_namn
JOIN mechanic_level AS ml
    ON m.mekaniker_niva = ml.mekaniker_niva
LEFT JOIN order_part AS op
    ON wo.order_nr = op.order_nr
LEFT JOIN part AS p
    ON op.artikel_nr = p.artikel_nr
LEFT JOIN supplier AS s
    ON p.leverantor = s.leverantor
ORDER BY wo.order_nr, p.artikel_nr;