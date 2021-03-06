{{config({
    "materialized": "incremental",
    "schema": "events",
    "tags":"hourly"
  })
}}

{% set rudder_relations = get_rudder_relations(schema=["events"], database='ANALYTICS', table_inclusions="'portal_events','mobile_events','rudder_webapp_events','segment_webapp_events','segment_mobile_events'") %}
{{ union_relations(relations = rudder_relations) }}