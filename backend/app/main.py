import logging
from fastapi import FastAPI
from app.api.wound import router as wound_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = FastAPI(title="suri")

app.include_router(wound_router, prefix="/wound")

@app.get("/")
def health():
    return {"status" : "ok"}