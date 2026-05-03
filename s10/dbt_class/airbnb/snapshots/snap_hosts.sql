{% snapshot snap_hosts %}

{{
    config(
        target_schema='snapshots',
        unique_key='id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

SELECT * FROM {{ source('airbnb_raw', 'raw_hosts') }}

{% endsnapshot %}
