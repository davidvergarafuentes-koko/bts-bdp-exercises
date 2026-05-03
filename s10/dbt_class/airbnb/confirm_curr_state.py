import duckdb
import numpy

conn = duckdb.connect("airbnb.duckdb")
print(conn.execute("SHOW ALL TABLES").df())
conn.close()
