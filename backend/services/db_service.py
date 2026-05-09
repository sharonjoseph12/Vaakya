import logging
from core.supabase_client import get_supabase
from datetime import datetime, timedelta, timezone

logger = logging.getLogger(__name__)


async def get_child_profile(profile_id: str):
    try:
        sb = get_supabase()
        result = sb.table("children").select("*").eq("id", profile_id).maybe_single().execute()
        return result.data
    except Exception as e:
        logger.warning(f"Could not fetch profile '{profile_id}': {e}")
        return None


async def save_chat_log(child_id: str, query: str, ai_reply: str, subject: str, language: str, source_page: str | None = None):
    try:
        sb = get_supabase()
        sb.table("chat_logs").insert({
            "child_id": child_id,
            "query": query,
            "ai_reply": ai_reply,
            "subject": subject,
            "language": language,
            "source_page": source_page,
        }).execute()
    except Exception as e:
        logger.warning(f"Could not save chat log: {e}")


async def get_weekly_logs(child_id: str):
    try:
        sb = get_supabase()
        seven_days_ago = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
        result = sb.table("chat_logs").select("*").eq("child_id", child_id).gte("created_at", seven_days_ago).execute()
        return result.data
    except Exception as e:
        logger.warning(f"Could not fetch weekly logs: {e}")
        return []


async def update_learner_level(child_id: str, level: str):
    try:
        sb = get_supabase()
        sb.table("children").update({"learner_level": level}).eq("id", child_id).execute()
    except Exception as e:
        logger.warning(f"Could not update learner level: {e}")

