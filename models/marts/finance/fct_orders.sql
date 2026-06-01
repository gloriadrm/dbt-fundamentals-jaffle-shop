with payments as (
    select * from {{ ref('stg_stripe__payment')}}
), 

orders as ( 
select customer_id, order_id from {{ ref('stg_jaffle_shop__orders') }}
), 

orders_with_payments as (

    select 
        orders.order_id,
        orders.customer_id, 
        payments.payment_amount,

    from orders

    left join payments using (order_id)
)

select * from orders_with_payments