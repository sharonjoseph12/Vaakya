import io
import logging
from fastapi import APIRouter, File, HTTPException, Query, UploadFile

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


@router.post("/upload-pdf")
async def upload_pdf(
    file: UploadFile = File(...),
    board: str = Query(..., description="Target board: cbse, icse, or state"),
):
    """Upload a PDF textbook and ingest its text into the board-specific ChromaDB collection."""
    # Import here to avoid circular issues and keep startup fast
    from services.rag_service import ingest_textbook

    # Validate board value early
    board_lower = board.lower()
    if board_lower not in {"cbse", "icse", "state"}:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid board '{board}'. Must be one of: cbse, icse, state.",
        )

    # Read uploaded bytes
    pdf_bytes = await file.read()

    # Extract text from PDF using PyPDF2
    try:
        import PyPDF2  # noqa: PLC0415

        reader = PyPDF2.PdfReader(io.BytesIO(pdf_bytes))
        pages_text = []
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                pages_text.append(page_text)
        full_text = "\n".join(pages_text)
    except Exception as e:
        logger.error(f"PDF parse error for '{file.filename}': {e}")
        raise HTTPException(
            status_code=400,
            detail=f"Could not parse the uploaded file as a PDF: {e}",
        )

    # Ingest into ChromaDB
    try:
        chunks_count = await ingest_textbook(
            text=full_text,
            board=board_lower,
            filename=file.filename or "unknown.pdf",
        )
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Ingestion error for '{file.filename}': {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Ingestion failed: {e}",
        )

    return {
        "filename": file.filename,
        "board": board_lower,
        "chunks_ingested": chunks_count,
        "status": "success",
    }
