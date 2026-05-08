from fastapi import APIRouter, HTTPException
from core.supabase_client import get_supabase
from pydantic import BaseModel
from typing import List

router = APIRouter(prefix="/api/v1/gamification", tags=["Gamification"])

class SyncRequest(BaseModel):
    profile_id: str
    streak_count: int
    badges_unlocked: List[str] = []

@router.post("/sync")
async def sync_stats(data: SyncRequest):
    """
    Sync mobile gamification stats with Supabase.
    """
    supabase = get_supabase()
    try:
        supabase.table("children") \
            .update({
                "streak_count": data.streak_count,
                "badges_unlocked": data.badges_unlocked
            }) \
            .eq("id", data.profile_id) \
            .execute()
        
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/stats/{profile_id}")
async def get_stats(profile_id: str):
    """
    Fetch aggregate analytics for a child profile.
    """
    sb = get_supabase()
    try:
        # 1. Total Questions (Chat Logs)
        chat_logs = sb.table("chat_logs").select("subject").eq("child_id", profile_id).execute().data or []
        total_questions = len(chat_logs)

        # 2. Total Stars (Sum of Quiz Scores)
        quiz_results = sb.table("quiz_results").select("score").eq("child_id", profile_id).execute().data or []
        total_stars = sum(q.get("score", 0) for q in quiz_results)

        # 3. Subject Breakdown
        subject_counts = {}
        for log in chat_logs:
            sub = log.get("subject", "Other") or "Other"
            subject_counts[sub] = subject_counts.get(sub, 0) + 1

        return {
            "status": "success",
            "data": {
                "total_questions": total_questions,
                "total_stars": total_stars,
                "subject_breakdown": subject_counts,
                "quiz_count": len(quiz_results)
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
