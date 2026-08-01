"""
Quick verification: create all tables via the direct Supabase connection,
then list what was created.
"""
# Import all models so they register with Base.metadata
import models  # noqa: F401
from sqlalchemy import create_engine, inspect

from app.core.config import settings
from app.db.database import Base

# Use the direct connection (port 5432) for DDL if available, else pooler
db_url = settings.DIRECT_DATABASE_URL if settings.DIRECT_DATABASE_URL else settings.DATABASE_URL
print(f"Using: {db_url[:40]}...")

direct_engine = create_engine(db_url, echo=False)

print(f"\nModels registered with Base.metadata: {list(Base.metadata.tables.keys())}")

# Create tables
print("\nRunning Base.metadata.create_all()...")
Base.metadata.create_all(bind=direct_engine)
print("Done!")

# Verify tables exist
inspector = inspect(direct_engine)
tables = inspector.get_table_names(schema="public")
print(f"\nTables in public schema: {tables}")

for table in tables:
    cols = [c["name"] for c in inspector.get_columns(table, schema="public")]
    print(f"  {table}: {cols}")

direct_engine.dispose()
