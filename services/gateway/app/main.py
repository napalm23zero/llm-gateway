from fastapi import FastAPI

app = FastAPI(title="LLM Gateway")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}