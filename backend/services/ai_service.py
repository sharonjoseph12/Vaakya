import logging
from google import genai
from google.genai import types
from core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()
client = genai.Client(api_key=settings.GEMINI_API_KEY)


async def generate_response(query: str, context: str, learner_level: str, language: str) -> str:
    """Generate a TTS-friendly, syllabus-locked text response using Gemini 2.0 Flash."""
    context_text = context if context else "No context available."
    prompt = f"""You are VoiceGuru, an expert, warm, and highly accurate tutor. Student Level: {learner_level}. Language: {language}.

CRITICAL RULES:
1. You MUST answer the child's question strictly using ONLY the information provided in the [TEXTBOOK CONTEXT] below. Do not use outside knowledge.
2. If the answer is not in the context, say exactly: That is outside your current syllabus, but great question!
3. DO NOT use markdown, asterisks, bullet points, hyphens, backticks, underscores, or any special formatting characters. Output plain spoken-word text only, as this will be read by a TTS engine.
4. Keep your answer under 4 short sentences. Each sentence must be 25 words or fewer.

[TEXTBOOK CONTEXT]
{context_text}

User Query: {query}"""

    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt,
    )
    return response.text


async def generate_vision_hint(image_bytes: bytes) -> str:
    """Generate a Socratic hint for a homework image. Never solves — only hints."""
    prompt = """You are VoiceGuru, a Socratic tutor helping a school student.

CRITICAL RULES:
1. NEVER reveal the answer or solve the problem shown in the image.
2. Give exactly ONE hint that guides the student to think through the problem themselves.
3. Your hint must be 3 sentences or fewer.
4. DO NOT use markdown, asterisks, bullet points, hyphens, backticks, underscores, or any special formatting. Plain spoken-word text only for TTS.
5. If you cannot read the image clearly, say: I cannot quite read that image. Could you try taking a sharper photo in better lighting?

Now look at the homework problem in the image and give your single Socratic hint."""

    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=[
            types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg"),
            prompt,
        ],
    )
    return response.text
