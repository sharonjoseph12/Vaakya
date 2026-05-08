from pydantic import BaseModel, Field
from typing import Optional

class ChatRequest(BaseModel):
    profile_id: str
    query: str = Field(..., max_length=500)
    subject: str
    language: str
    learner_level: str  # Beginner, Intermediate, Advanced

class ChatResponse(BaseModel):
    ai_reply: str
    source_textbook_page: Optional[str] = None
    status: str
