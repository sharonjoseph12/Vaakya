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


class QuizGenerateRequest(BaseModel):
    child_id: str
    subject: str


class QuizQuestion(BaseModel):
    question: str
    options: list[str]
    correct_answer: str


class QuizGenerateResponse(BaseModel):
    questions: list[QuizQuestion]
    status: str


class QuizSubmitRequest(BaseModel):
    child_id: str
    subject: str
    score: int = Field(..., ge=0, le=3)


class QuizSubmitResponse(BaseModel):
    previous_level: str
    new_level: str
    message: str
    status: str


class VideoResponse(BaseModel):
    video_id: str
    title: str
    thumbnail_url: str
    status: str
