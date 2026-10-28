
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