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

    prompt = f"""Generate exactly 3 multiple choice questions for a {level} level student on {subject}.
Return ONLY a JSON array with no markdown, no code fences, no extra text.
Each element must have: "question" (string), "options" (array of 4 strings labeled A-D), "correct_answer" (one of A,B,C,D).
Example: [{{"question":"What is 2+2?","options":["A. 3","B. 4","C. 5","D. 6"],"correct_answer":"B"}}]"""

    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt,
    )

    raw = response.text.strip()
    # Strip markdown code fences if Gemini wraps the JSON (handles ```json and ```)
    if "```" in raw:
        # Find first [ and last ] to extract the JSON array
        start = raw.find('[')
        end = raw.rfind(']') + 1
        if start != -1 and end != -1:
            raw = raw[start:end]

    try:
        return json.loads(raw)
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse Gemini quiz JSON: {e}. Raw output: {raw}")
        # Return a simple fallback question if parsing fails
        return [{
            "question": "VoiceGuru is preparing your next challenge! For now, what is 10 plus 10?",
            "options": ["A. 15", "B. 20", "C. 25", "D. 30"],
            "correct_answer": "B"
        }]


async def evaluate_quiz(child_id: str, subject: str, score: int) -> dict:
    profile = await get_child_profile(child_id)
    previous_level = profile.get("learner_level", "Intermediate") if profile else "Intermediate"

    if score == 3:
        new_level = "Advanced"
        message = "Outstanding! You have been promoted to Advanced level. Future answers will include real-world applications."
    elif score <= 1:
        new_level = "Beginner"
        message = "No worries! Let us slow down and use simpler examples to help you understand better."
    else:
        # score == 2
        new_level = previous_level
        message = "Good effort! Keep practicing and you will level up soon."

    # Only write to Supabase if the level actually changed
    if new_level != previous_level:
        await update_learner_level(child_id, new_level)

    # Always persist the quiz result
    sb = get_supabase()
    sb.table("quiz_results").insert({
        "child_id": child_id,
        "subject": subject,
        "score": score,
        "total": 3,
        "difficulty_before": previous_level,
        "difficulty_after": new_level,
    }).execute()

    logger.info(f"Quiz evaluated for child {child_id}: {previous_level} → {new_level} (score {score}/3)")

    return {
        "previous_level": previous_level,
        "new_level": new_level,
        "message": message,
    }
