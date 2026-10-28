/*
 Expect the following error from the insert into work_order:
 ERROR: new row for relation "work_order" violates check constraint "work_order_arbetstid_check"
 Detail: Failing row contains (9999, 2026-10-01, WSBC-4411, Oskar Nyberg, -30, 1).
 */
insert
	into
	work_order (
    order_nr,
	order_datum,
	kund_id,
	cykel_ramnr,
	mekaniker_namn,
	arbetstid_min
)
values (
    9999,
    '2026-10-01',
    1,
    'WSBC-4411',
    'Oskar Nyberg',
    -30
);

-- Demonstrate a rejected foreign-key constraint.
-- Attempt to insert an order-part row referencing a work order that does not exist.
/*
 * Expect the following error from the insert into order_part:
 * ERROR: insert or update on table "order_part" violates foreign key constraint "order_part_work_order_fk"
 * Detail: Key (order_nr)=(9999) is not present in table "work_order".
 */
insert
	into
	order_part (
	order_nr,
	artikel_nr,
	antal,
	styckpris
)
values (
	9999,
	'KE-100',
    1,
    259.00
);

/*
 * Expect the following error from the insert into customer:
 * ERROR: new row for relation "customer" violates check constraint "customer_email_check"
 * Detail: Failing row contains (4, Test Customer, invalid-email.com).
 */
insert
	into
	customer (kund_namn,
	kund_epost)
values ('Test Customer',
'invalid-email.com');
