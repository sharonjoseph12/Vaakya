from fastapi import APIRouter, UploadFile, File

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])

@router.post("/upload-pdf")
async def upload_pdf(file: UploadFile = File(...)):
    # Placeholder for PDF ingestion logic
    return {"filename": file.filename, "status": "PDF received for processing"}
