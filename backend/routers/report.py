from fastapi import APIRouter, HTTPException
from services.report_service import send_weekly_reports
import asyncio

router = APIRouter(prefix="/api/v1/reports", tags=["Reports"])

@router.post("/send-now")
async def trigger_manual_report(parent_phone: str = None):
    """
    Manually trigger a weekly report for a specific parent or all parents.
    """
    try:
        # In a real scenario, we might filter by parent_phone
        # For this hackathon, we trigger the existing logic
        await asyncio.to_thread(send_weekly_reports)
        return {"status": "success", "message": "Report generation triggered"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
