select
    customer_id,
    order_placed_at,
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'order_placed_at']) }} as primary_key,
    count(*) as orders
from {{ ref('stg_jaffle_shop__orders') }}
group by 1,2