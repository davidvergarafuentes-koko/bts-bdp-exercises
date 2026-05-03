import duckdb

conn = duckdb.connect("airbnb.duckdb")
conn.execute("""
    UPDATE raw_hosts
    SET is_superhost = 't',
        updated_at = '2025-11-01'
    WHERE id = 102
""")
conn.close()
print("Host 102 updated: is_superhost = true")
