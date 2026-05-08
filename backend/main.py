from fastapi import FastAPI
from routers import chat, admin
import uvicorn

app = FastAPI(title="VoiceGuru API", version="1.0.0")

app.include_router(chat.router)
app.include_router(admin.router)

@app.get("/")
async def root():
    return {"message": "VoiceGuru Backend is Online"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
