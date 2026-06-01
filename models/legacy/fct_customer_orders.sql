with

-- Import staging CTEs

customers as ( 
    select * 
    from {{ ref('stg_jaffle_shop__customers') }}
),

paid_orders as ( 
    select * 
    from {{ ref('int_orders') }}
),

-- Final CTE
final as (
    select
        paid_orders.order_id,
        paid_orders.customer_id,
        paid_orders.order_placed_at,
        paid_orders.order_status,
        paid_orders.total_amount_paid,
        paid_orders.payment_finalized_date,
        customers.customer_first_name,
        customers.customer_last_name,

        -- Número de transacción global
        row_number() over (
            order by paid_orders.order_id
        ) as transaction_seq,

        -- Número de pedido dentro de cada cliente
        row_number() over (
            partition by paid_orders.customer_id
            order by paid_orders.order_id
        ) as customer_sales_seq,

        -- New vs Return
        case
            when first_value(paid_orders.order_placed_at) over (
                partition by paid_orders.customer_id
                order by paid_orders.order_placed_at
            ) = paid_orders.order_placed_at
            then 'new'
            else 'return'
        end as nvsr,

        -- Customer Lifetime Value
        sum(paid_orders.total_amount_paid) over (
            partition by paid_orders.customer_id
            order by paid_orders.order_id
        ) as customer_lifetime_value,

        -- First Date Of Sale
        first_value(paid_orders.order_placed_at) over (
            partition by paid_orders.customer_id
            order by paid_orders.order_placed_at
        ) as fdos,

        -- Fecha del pedido más reciente
        max(paid_orders.order_placed_at) over (
            partition by paid_orders.customer_id
        ) as most_recent_order_date,

        -- Número total de pedidos
        count(*) over (
            partition by paid_orders.customer_id
        ) as number_of_orders

    from paid_orders
    left join customers
        on paid_orders.customer_id = customers.customer_id
)

-- simple select statement
select * from final
order by order_id
