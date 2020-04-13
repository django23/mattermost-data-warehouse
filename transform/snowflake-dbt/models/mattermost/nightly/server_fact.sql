{{config({
    "materialized": 'table',
    "schema": "mattermost"
  })
}}

WITH server_details AS (
    SELECT
        server_id,
        MIN(date) AS first_active_date,
        MAX(CASE WHEN in_security OR in_mm2_server THEN date ELSE NULL END) AS last_active_date,
        MIN(CASE WHEN in_security THEN date ELSE NULL END) as first_telemetry_active_date,
        MAX(CASE WHEN in_security THEN date ELSE NULL END) AS last_telemetry_active_date,
        MAX(active_user_count) AS max_active_user_count,
        MAX(CASE WHEN active_user_count > 0 THEN date ELSE NULL END) AS last_active_user_date,
        MAX(CASE WHEN license_id1 IS NOT NULL or license_id2 IS NOT NULL THEN date ELSE NULL END) AS last_active_license_date
    FROM {{ ref('server_daily_details') }}
    GROUP BY 1
),
server_fact AS (
    SELECT
        server_details.server_id,
        server_daily_details.version,
        server_daily_details.account_sfid AS last_account_sfid,
        server_daily_details.license_id1 AS last_license_id1,
        server_daily_details.license_id2 AS last_license_id2,
        server_details.first_active_date,
        server_details.last_active_date,
        server_details.first_telemetry_active_date,
        server_details.last_telemetry_active_date,
        server_details.max_active_user_count,
        server_details.last_active_user_date,
        server_details.last_active_license_date,
        nps.nps_users,
        nps.nps_score,
        nps.promoters,
        nps.detractors,
        nps.passives,
        nps.avg_score                   AS avg_nps_user_score
    FROM server_details 
    JOIN {{ ref('server_daily_details') }}
        ON server_details.server_id = server_daily_details.server_id
        AND server_details.last_active_date = server_daily_details.date
    LEFT JOIN {{ ref('nps_server_monthly_score') }} nps
        ON server_details.server_id = nps.server_id
        AND nps.month = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 DAY'))
    {{ dbt_utils.group_by(n=18) }}
)
SELECT *
FROM server_fact