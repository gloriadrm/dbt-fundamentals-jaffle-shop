{{
    config(
        materialized='incremental', 
        incremental_strategy = 'merge',
        unique_key = 'order_id'
    )
}}

with payments as (
    select * from {{ ref('stg_stripe__payment') }}
), 

succesfull_payments as (
    select
        order_id,
        sum (case when payment_status = 'success' then payment_amount end) as payment_amount
    from payments
    group by 1
),

orders as ( 
    select 
        customer_id, 
        order_id, 
        order_placed_at
    from {{ ref('stg_jaffle_shop__orders') }}
    
    {% if is_incremental() %}
        where order_placed_at > (select max(order_placed_at) from {{ this }}) 
    {% endif %}
), 

orders_with_payments as (
    select 
        orders.order_id,
        orders.customer_id, 
        orders.order_placed_at,
        coalesce (succesfull_payments.payment_amount,0) as payment_amount
    from orders
    left join succesfull_payments using (order_id)
)

select * from orders_with_payments