import logging
from fastapi import APIRouter, File, UploadFile
from models.schemas import VisionResponse
from services.ai_service import generate_vision_hint

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/chat", tags=["vision"])

VISION_FALLBACK = "I can't quite read that image. Can you take a sharper photo?"


@router.post("/vision", response_model=VisionResponse)
async def vision_hint(file: UploadFile = File(...)):
    """Accept a homework image and return a Socratic hint — never the answer."""
    try:
        image_bytes = await file.read()
        hint = await generate_vision_hint(image_bytes)
        return VisionResponse(ai_reply=hint, status="success")
    except Exception as e:
        logger.error(f"Vision endpoint error: {e}")
        return VisionResponse(ai_reply=VISION_FALLBACK, status="error")
