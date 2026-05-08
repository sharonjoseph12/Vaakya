import logging
from fastapi import APIRouter
from models.schemas import VideoResponse
from services.youtube_service import search_video

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/media", tags=["media"])


@router.get("/video", response_model=VideoResponse)
async def get_video(query: str):
    try:
        result = await search_video(query)
        if result:
            return VideoResponse(**result, status="success")
        return VideoResponse(
            video_id="",
            title="No video found",
            thumbnail_url="",
            status="not_found",
        )
    except Exception as e:
        logger.error(f"YouTube search failed for query '{query}': {e}")
        return VideoResponse(
            video_id="",
            title="Video search failed",
            thumbnail_url="",
            status="error",
        )
