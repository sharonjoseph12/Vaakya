from contextlib import asynccontextmanager
from fastapi import FastAPI
from apscheduler.schedulers.background import BackgroundScheduler
from routers import chat, admin, vision
from routers import quiz as quiz_router
from routers import youtube as youtube_router
from services.report_service import send_weekly_reports
import uvicorn

scheduler = BackgroundScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: schedule weekly parent reports — Sunday 18:00 IST (12:30 UTC)
    scheduler.add_job(send_weekly_reports, "cron", day_of_week="sun", hour=12, minute=30)
    scheduler.start()
    yield
    # Shutdown
    scheduler.shutdown(wait=False)


app = FastAPI(title="VoiceGuru API", version="1.0.0", lifespan=lifespan)

app.include_router(chat.router)
app.include_router(vision.router)
app.include_router(admin.router)
app.include_router(quiz_router.router)
app.include_router(youtube_router.router)


@app.get("/")
async def root():
    return {"message": "VoiceGuru Backend is Online"}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
