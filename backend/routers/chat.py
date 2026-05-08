from fastapi import APIRouter, HTTPException
from models.schemas import ChatRequest, ChatResponse
from services.ai_service import generate_response
from services.rag_service import search_textbook
from services.db_service import save_chat_log

router = APIRouter(prefix="/api/v1/chat", tags=["chat"])

@router.post("/ask", response_model=ChatResponse)
async def ask_question(request: ChatRequest):
    try:
        # 1. Search ChromaDB
        context = await search_textbook(request.query, request.subject)
        
        # 2. Generate AI Response
        ai_reply = await generate_response(
            request.query, 
            context, 
            request.learner_level, 
            request.language
        )
        
        # 3. Save to Firestore (Mock user_id for now or extract from auth)
        # For Phase 1, we assume user_id is linked to profile or provided elsewhere
        # await save_chat_log("default_user", request.profile_id, request.query, ai_reply, request.subject)
        
        return ChatResponse(
            ai_reply=ai_reply,
            source_textbook_page=None, # Update if rag returns metadata
            status="success"
        )
    except Exception as e:
        return ChatResponse(
            ai_reply="I'm thinking a bit too hard right now, please ask again!",
            status="error"
        )
