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
