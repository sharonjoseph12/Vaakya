from core.supabase_client import get_supabase
from datetime import datetime, timedelta, timezone


async def get_child_profile(profile_id: str):
    sb = get_supabase()
    result = sb.table("children").select("*").eq("id", profile_id).single().execute()
    return result.data


async def save_chat_log(child_id: str, query: str, ai_reply: str, subject: str, language: str, source_page: str | None = None):
    sb = get_supabase()
    sb.table("chat_logs").insert({
        "child_id": child_id,
        "query": query,
        "ai_reply": ai_reply,
        "subject": subject,
        "language": language,
        "source_page": source_page,
    }).execute()


async def get_weekly_logs(child_id: str):
    sb = get_supabase()
    seven_days_ago = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
    result = sb.table("chat_logs").select("*").eq("child_id", child_id).gte("created_at", seven_days_ago).execute()
    return result.data


async def update_learner_level(child_id: str, level: str):
    sb = get_supabase()
    sb.table("children").update({"learner_level": level}).eq("id", child_id).execute()
