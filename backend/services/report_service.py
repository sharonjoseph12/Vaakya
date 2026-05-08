from google import genai
from twilio.rest import Client as TwilioClient
from core.config import get_settings
from core.supabase_client import get_supabase
from datetime import datetime, timedelta, timezone
import logging

logger = logging.getLogger(__name__)
settings = get_settings()
gemini_client = genai.Client(api_key=settings.GEMINI_API_KEY)


def _get_twilio_client() -> TwilioClient | None:
    if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_AUTH_TOKEN:
        return None
    return TwilioClient(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)


def send_weekly_reports():
    """Cron job: runs every Sunday 18:00. Fetches each child's weekly logs,
    generates an AI summary, and WhatsApps the parent."""
    sb = get_supabase()
    twilio = _get_twilio_client()
    if not twilio:
        logger.warning("Twilio not configured — skipping weekly reports.")
        return

    seven_days_ago = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()

    # Fetch all children with their parent info
    children = sb.table("children").select("id, name, parent_id").execute().data or []

    for child in children:
        try:
            # Get chat logs for the week
            logs = (
                sb.table("chat_logs")
                .select("query, subject, created_at")
                .eq("child_id", child["id"])
                .gte("created_at", seven_days_ago)
                .execute()
                .data
            )

            if not logs:
                continue

            # Get parent phone
            parent = sb.table("parents").select("phone").eq("id", child["parent_id"]).single().execute().data
            if not parent or not parent.get("phone"):
                continue

            # Format logs for Gemini
            log_text = "\n".join(
                f"- [{l.get('subject', 'General')}] {l['query']}" for l in logs
            )

            prompt = f"""Analyze this student's weekly chat logs. The student's name is {child['name']}.
Generate a 3-sentence summary for their parent via WhatsApp.
Tone: Professional and encouraging. Mention specific subjects and progress.

Chat logs:
{log_text}"""

            response = gemini_client.models.generate_content(
                model="gemini-2.0-flash",
                contents=prompt
            )

            summary = response.text.strip()

            # Send WhatsApp via Twilio
            twilio.messages.create(
                from_=settings.TWILIO_WHATSAPP_FROM,
                to=f"whatsapp:{parent['phone']}",
                body=f"📚 VoiceGuru Weekly Report\n\n{summary}",
            )
            logger.info(f"Sent report for child {child['name']} to {parent['phone']}")

        except Exception as e:
            logger.error(f"Failed to send report for child {child['id']}: {e}")
