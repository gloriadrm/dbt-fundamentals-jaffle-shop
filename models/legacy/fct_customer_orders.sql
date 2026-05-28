with

-- Import CTEs
customers as (
    select * from {{ source('jaffle_shop', 'customers') }}
),

orders as (
    select * from {{ source('jaffle_shop', 'orders') }}
),

payments as (
    select * from {{ source('stripe', 'payment') }}
),

-- Logical CTEs
order_payments as (
    select
        orderid as order_id,
        max(created) as payment_finalized_date,
        sum(amount) / 100.0 as total_amount_paid
    from payments
    where status <> 'fail'
    group by 1
),

paid_orders as (
    select
        orders.id as order_id,
        orders.user_id as customer_id,
        orders.order_date as order_placed_at,
        orders.status as order_status,
        order_payments.total_amount_paid,
        order_payments.payment_finalized_date,
        customers.first_name as customer_first_name,
        customers.last_name as customer_last_name
    from orders
    left join order_payments
        on orders.id = order_payments.order_id
    left join customers
        on orders.user_id = customers.id
),

-- Final CTE
final as (
    select
        paid_orders.*,

        -- Número de transacción global
        row_number() over (
            order by paid_orders.order_id
        ) as transaction_seq,

        -- Número de pedido dentro de cada cliente
        row_number() over (
            partition by customer_id
            order by paid_orders.order_id
        ) as customer_sales_seq,

        -- New vs Return: 'new' si es el primer pedido del cliente
        case
            when first_value(order_placed_at) over (
                partition by customer_id
                order by order_placed_at
            ) = order_placed_at
            then 'new'
            else 'return'
        end as nvsr,

        -- Customer Lifetime Value: running total del gasto del cliente
        sum(total_amount_paid) over (
            partition by customer_id
            order by paid_orders.order_id
        ) as customer_lifetime_value,

        -- First Date Of Sale: fecha del primer pedido del cliente
        first_value(order_placed_at) over (
            partition by customer_id
            order by order_placed_at
        ) as fdos,

        -- Fecha del pedido más reciente del cliente
        max(order_placed_at) over (
            partition by customer_id
        ) as most_recent_order_date,

        -- Número total de pedidos del cliente
        count(*) over (
            partition by customer_id
        ) as number_of_orders

    from paid_orders
)

-- simple select statement
select * from final
order by order_id
