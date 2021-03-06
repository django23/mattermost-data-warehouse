{{config({
    "materialized": "incremental",
    "schema": "events",
    "tags":"hourly"
  })
}}

SELECT *
FROM {{ source('mm_telemetry_prod', 'event') }}
WHERE timestamp::date <= CURRENT_DATE
{% if is_incremental() %}

AND timestamp::date > (SELECT MAX(timestamp) FROM {{this}})

{% endif %}