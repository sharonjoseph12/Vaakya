from google import genai
from core.config import get_settings

settings = get_settings()
client = genai.Client(api_key=settings.GEMINI_API_KEY)

async def generate_response(query: str, context: str, learner_level: str, language: str):
    prompt = f"""
You are VoiceGuru, an expert, warm, and highly accurate tutor. Student Level: {learner_level}. Language: {language}. 

CRITICAL RULES:
1. You MUST answer the child's question strictly using ONLY the information provided in the [TEXTBOOK CONTEXT] below. Do not use outside knowledge.
2. If the answer is not in the context, say 'That is outside your current syllabus, but great question!' in the chosen language.
3. DO NOT use markdown, asterisks, or bullet points. Output plain, spoken-word text only, as this will be read by a TTS engine.
4. Keep your answer under 4 short sentences.

[TEXTBOOK CONTEXT]
{context if context else 'No context available.'}

User Query: {query}
"""
    
    response = client.models.generate_content(
        model="gemini-2.0-flash", # Using flash 2.0 as it's the current recommended
        contents=prompt
    )
    
    return response.text
