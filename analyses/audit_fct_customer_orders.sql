----------------------------------------------------------------
-- Compare row counts
----------------------------------------------------------------
{% set old_relation = adapter.get_relation(
    database = "ANALYTICS",
    schema = "dbt_gdrm",
    identifier = "customer_orders_legacy"
) -%}

{% set dbt_relation = ref('fct_customer_orders') %}

{{ audit_helper.compare_row_counts(
    a_relation = old_relation,
    b_relation = dbt_relation
) }}

----------------------------------------------------------------
-- Compare all columns
----------------------------------------------------------------

{% set old_relation = adapter.get_relation(
    database = "ANALYTICS",
    schema = "dbt_gdrm",
    identifier = "customer_orders_legacy"
) -%}

{% set dbt_relation = ref('fct_customer_orders') %}

{% if execute %}

{{ audit_helper.compare_all_columns(
    a_relation = old_relation,
    b_relation = dbt_relation,
    primary_key = "order_id"
) }}

{% endif%}
----------------------------------------------------------------

