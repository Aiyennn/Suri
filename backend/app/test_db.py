from sqlalchemy import text
from core.database import engine
from core.config import settings

print(settings.DATABASE_URL)

with engine.connect() as conn:
    result = conn.execute(text("SELECT 1"))
    print("Database connected successfully:", result.scalar())