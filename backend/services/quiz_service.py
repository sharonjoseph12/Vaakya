import json
import logging
from google import genai
from core.config import get_settings
from services.db_service import get_child_profile, update_learner_level
from core.supabase_client import get_supabase

logger = logging.getLogger(__name__)
settings = get_settings()
client = genai.Client(api_key=settings.GEMINI_API_KEY)


async def generate_quiz(child_id: str, subject: str) -> list[dict]:
    profile = await get_child_profile(child_id)
    level = profile.get("learner_level", "Intermediate") if profile else "Intermediate"

    prompt = f"""Generate exactly 10 multiple choice questions for a {level} level student on {subject}.
Return ONLY a JSON array with no markdown, no code fences, no extra text.
Each element must have: "question" (string), "options" (array of 4 strings labeled A-D), "correct_answer" (one of A,B,C,D).
Example: [{{"question":"What is 2+2?","options":["A. 3","B. 4","C. 5","D. 6"],"correct_answer":"B"}}]"""

    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt,
    )

    raw = response.text.strip()
    # Strip markdown code fences if Gemini wraps the JSON
    if raw.startswith("```"):
        raw = raw.split("\n", 1)[1]
        raw = raw.rsplit("```", 1)[0].strip()

    return json.loads(raw)


async def evaluate_quiz(child_id: str, subject: str, score: int) -> dict:
    profile = await get_child_profile(child_id)
    previous_level = profile.get("learner_level", "Intermediate") if profile else "Intermediate"

    if score >= 8:
        new_level = "Advanced"
        message = "Outstanding! You have been promoted to Advanced level. Future answers will include real-world applications."
    elif score <= 4:
        new_level = "Beginner"
        message = "No worries! Let us slow down and use simpler examples to help you understand better."
    else:
        # score == 2
        new_level = previous_level
        message = "Good effort! Keep practicing and you will level up soon."

    # Only write to Supabase if the level changed AND the profile exists
    if new_level != previous_level and profile is not None:
        await update_learner_level(child_id, new_level)

    # Persist quiz result — skip if it's a demo profile with no real DB entry
    try:
        sb = get_supabase()
        sb.table("quiz_results").insert({
            "child_id": child_id,
            "subject": subject,
            "score": score,
            "total": 10,
            "difficulty_before": previous_level,
            "difficulty_after": new_level,
        }).execute()
    except Exception as e:
        logger.warning(f"Could not save quiz result for '{child_id}': {e}")

    logger.info(f"Quiz evaluated for child {child_id}: {previous_level} → {new_level} (score {score}/3)")

    return {
        "previous_level": previous_level,
        "new_level": new_level,
        "message": message,
    }

