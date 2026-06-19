from fastapi import FastAPI

app = FastAPI(
    title="suri"
)

@app.get("/")
def root():
    return {"status" : "running"}