{{config({
    "materialized": 'incremental',
    "schema": "mattermost",
    "unique_key": 'id'
  })
}}

WITH license        AS (
    SELECT
        l.customerid
      , l.company
      , l.number
      , l.email
      , l.stripeid
      , l.licenseid
      , to_timestamp(l.issuedat / 1000)::DATE  AS issuedat
      , to_timestamp(l.expiresat / 1000)::DATE AS expiresat
    FROM {{ source('licenses', 'licenses') }} l
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),

     max_date        AS (
         SELECT
             l.license_id
           , l.user_id         AS server_id
           , max(l.timestamp)  AS max_timestamp
         FROM {{ source('mattermost2','license') }} l
         GROUP BY 1, 2
     ),

     license_details AS (
         SELECT
             l.license_id
           , l.user_id                           AS server_id
           , l.customer_id
           , l.edition
           , to_timestamp(l.issued / 1000)::DATE AS issued_date
           , to_timestamp(l._start / 1000)::DATE AS start_date
           , to_timestamp(l.expire / 1000)::DATE AS expire_date
           , users
           , l.feature_cluster
           , l.feature_compliance
           , l.feature_custom_brand
           , l.feature_custom_permissions_schemes
           , l.feature_data_retention
           , l.feature_elastic_search
           , l.feature_email_notification_contents
           , l.feature_future
           , l.feature_google
           , l.feature_guest_accounts
           , l.feature_guest_accounts_permissions
           , l.feature_id_loaded
           , l.feature_ldap
           , l.feature_ldap_groups
           , l.feature_lock_teammate_name_display
           , l.feature_message_export
           , l.feature_metrics
           , l.feature_mfa
           , l.feature_mhpns
           , l.feature_office365
           , l.feature_password
           , l.feature_saml
           , MAX(m.max_timestamp)                 AS timestamp
         FROM {{ source('mattermost2' , 'license') }} l
              JOIN max_date           m
                   ON l.license_id = m.license_id
                       AND l.user_id = m.server_id
                       AND l.timestamp = m.max_timestamp
         GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
                , 13, 14, 15, 16, 17, 18, 19, 20, 21, 22
                , 23, 24, 25, 26, 27, 28, 29, 30
     ),

     license_overview AS (
         SELECT 
            lo.licenseid
          , lo.company
          , lo.stripeid
          , lo.customerid
          , lo.license_email
          , lo.master_account_sfid
          , lo.master_account_name
          , lo.account_sfid
          , lo.account_name
          , lo.contact_sfid
          , lo.contact_email
         FROM {{ ref('license_overview') }} lo
         GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
         , 10, 11
     ),

     license_details_all AS (
         SELECT
             ld.license_id
           , ld.server_id
           , ld.customer_id
           , l.company
           , ld.edition
           , ld.issued_date
           , ld.start_date
           , ld.expire_date
           , lo.master_account_sfid
           , lo.master_account_name
           , lo.account_sfid
           , lo.account_name
           , l.email                                                                                AS license_email
           , lo.contact_sfid
           , lo.contact_email
           , l.number
           , l.stripeid
           , ld.users
           , ld.feature_cluster
           , ld.feature_compliance
           , ld.feature_custom_brand
           , ld.feature_custom_permissions_schemes
           , ld.feature_data_retention
           , ld.feature_elastic_search
           , ld.feature_email_notification_contents
           , ld.feature_future
           , ld.feature_google
           , ld.feature_guest_accounts
           , ld.feature_guest_accounts_permissions
           , ld.feature_id_loaded
           , ld.feature_ldap
           , ld.feature_ldap_groups
           , ld.feature_lock_teammate_name_display
           , ld.feature_message_export
           , ld.feature_metrics
           , ld.feature_mfa
           , ld.feature_mhpns
           , ld.feature_office365
           , ld.feature_password
           , ld.feature_saml
           , ld.timestamp
           , {{ dbt_utils.surrogate_key('ld.license_id', 'ld.server_id','ld.customer_id') }} AS id
         FROM license_details    ld
              LEFT JOIN license l
                        ON ld.license_id = l.licenseid
              LEFT JOIN license_overview lo
                        ON ld.license_id = lo.licenseid
         GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
                , 13, 14, 15, 16, 17, 18, 19, 20, 21, 22
                , 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
                , 33, 34, 35, 36, 37, 38, 39, 40, 41, 42
     ),

     licenses as (
         SELECT
             ld.license_id
           , ld.server_id
           , ld.customer_id
           , ld.company
           , ld.edition
           , ld.issued_date
           , ld.start_date
           , CASE WHEN lead(ld.start_date, 1) OVER (PARTITION BY ld.server_id ORDER BY ld.start_date, ld.users) <= ld.expire_date
                 THEN lead(ld.start_date, 1) OVER (PARTITION BY ld.server_id ORDER BY ld.start_date, ld.users) - INTERVAL '1 DAY'
             ELSE
                 ld.expire_date END      AS expire_date
           , ld.master_account_sfid
           , ld.master_account_name
           , ld.account_sfid
           , ld.account_name
           , ld.license_email
           , ld.contact_sfid
           , ld.contact_email
           , ld.number
           , ld.stripeid
           , ld.users
           , ld.feature_cluster
           , ld.feature_compliance
           , ld.feature_custom_brand
           , ld.feature_custom_permissions_schemes
           , ld.feature_data_retention
           , ld.feature_elastic_search
           , ld.feature_email_notification_contents
           , ld.feature_future
           , ld.feature_google
           , ld.feature_guest_accounts
           , ld.feature_guest_accounts_permissions
           , ld.feature_id_loaded
           , ld.feature_ldap
           , ld.feature_ldap_groups
           , ld.feature_lock_teammate_name_display
           , ld.feature_message_export
           , ld.feature_metrics
           , ld.feature_mfa
           , ld.feature_mhpns
           , ld.feature_office365
           , ld.feature_password
           , ld.feature_saml
           , ld.timestamp
           , ld.id
         FROM license_details_all ld
     )
SELECT *
FROM licenses