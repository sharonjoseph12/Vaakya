import logging
from fastapi import APIRouter
from models.schemas import ChatRequest, ChatResponse
from services.ai_service import generate_response
from services.rag_service import search_textbook
from services.db_service import get_child_profile, save_chat_log

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/chat", tags=["chat"])


@router.post("/ask", response_model=ChatResponse)
async def ask_question(request: ChatRequest):
    try:
        # 1. Fetch child profile to get board (for board-specific RAG)
        profile = await get_child_profile(request.profile_id)
        board = profile.get("board", "cbse").lower() if profile else "cbse"

        # 2. Search board-specific ChromaDB collection
        context = await search_textbook(request.query, board)

        # 3. Generate AI response via Gemini
        ai_reply = await generate_response(
            query=request.query,
            context=context or "",
            learner_level=request.learner_level,
            language=request.language,
        )

        # 4. Persist chat log to Supabase (non-blocking — log failure but don't fail request)
        try:
            await save_chat_log(
                child_id=request.profile_id,
                query=request.query,
                ai_reply=ai_reply,
                subject=request.subject,
                language=request.language,
                source_page=None,
            )
        except Exception as db_err:
            logger.error(f"Failed to save chat log for profile {request.profile_id}: {db_err}")

        return ChatResponse(
            ai_reply=ai_reply,
            source_textbook_page=None,
            status="success",
        )

    except Exception as e:
        logger.error(f"Chat pipeline error for profile {request.profile_id}: {e}")
        return ChatResponse(
            ai_reply="I'm thinking a bit too hard right now, please ask again!",
            source_textbook_page=None,
            status="error",
        )
