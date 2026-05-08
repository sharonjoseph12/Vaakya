import logging
from fastapi import APIRouter
from models.schemas import (
    QuizGenerateRequest, QuizGenerateResponse, QuizQuestion,
    QuizSubmitRequest, QuizSubmitResponse,
)
from services.quiz_service import generate_quiz, evaluate_quiz

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/quiz", tags=["quiz"])


@router.post("/generate", response_model=QuizGenerateResponse)
async def generate_quiz_endpoint(request: QuizGenerateRequest):
    try:
        questions_raw = await generate_quiz(request.child_id, request.subject)
        questions = [QuizQuestion(**q) for q in questions_raw]
        return QuizGenerateResponse(questions=questions, status="success")
    except Exception as e:
        logger.error(f"Quiz generation failed for child {request.child_id}: {e}")
        return QuizGenerateResponse(questions=[], status="error")


@router.post("/submit", response_model=QuizSubmitResponse)
async def submit_quiz_endpoint(request: QuizSubmitRequest):
    try:
        result = await evaluate_quiz(request.child_id, request.subject, request.score)
        return QuizSubmitResponse(**result, status="success")
    except Exception as e:
        logger.error(f"Quiz submission failed for child {request.child_id}: {e}")
        return QuizSubmitResponse(
            previous_level="Unknown",
            new_level="Unknown",
            message="We could not save your quiz result right now. Please try again.",
            status="error",
        )
