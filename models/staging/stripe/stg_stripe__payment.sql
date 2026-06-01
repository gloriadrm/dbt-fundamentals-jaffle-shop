with
    payments as (select * from {{ source("stripe", "payment") }}),

    transformed as (
        select
            id as payment_id,
            orderid as order_id,
            created as payment_created_at,
            {{ cents_to_dollars("amount", 4)}} as payment_amount,
            paymentmethod as payment_method,
            status as payment_status,
            _batched_at
        from payments
    )

select *
from transformed
