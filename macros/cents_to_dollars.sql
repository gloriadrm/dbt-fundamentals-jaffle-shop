{% macro cents_to_dollars(col_name,decimals=2)-%}
        ROUND( {{col_name}} / 100 , {{decimals}} )
{%- endmacro%}