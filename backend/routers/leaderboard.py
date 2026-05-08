from fastapi import APIRouter, HTTPException, Depends
from core.supabase_client import get_supabase
from typing import List

router = APIRouter(prefix="/api/v1/leaderboard", tags=["Leaderboard"])

@router.get("/")
async def get_leaderboard(limit: int = 10):
    """
    Fetch top students based on streak count.
    """
    supabase = get_supabase()
    try:
        response = supabase.table("children") \
            .select("name, streak_count, grade, board") \
            .order("streak_count", desc=True) \
            .limit(limit) \
            .execute()
        
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
