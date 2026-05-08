import firebase_admin
from firebase_admin import credentials, firestore
from core.config import get_settings
import datetime

settings = get_settings()

if not firebase_admin._apps:
    cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()

async def get_child_profile(user_id: str, profile_id: str):
    doc_ref = db.collection("users").document(user_id).collection("profiles").document(profile_id)
    doc = doc_ref.get()
    return doc.to_dict() if doc.exists else None

async def save_chat_log(user_id: str, profile_id: str, query: str, ai_reply: str, subject: str):
    log_ref = db.collection("users").document(user_id).collection("profiles").document(profile_id).collection("chat_logs").document()
    log_ref.set({
        "query": query,
        "ai_reply": ai_reply,
        "subject": subject,
        "timestamp": firestore.SERVER_TIMESTAMP
    })
