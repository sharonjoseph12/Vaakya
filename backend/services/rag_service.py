import chromadb
from core.config import get_settings

settings = get_settings()
chroma_client = chromadb.PersistentClient(path=settings.CHROMA_DB_PATH)

async def search_textbook(query: str, subject: str):
    # Determine collection based on subject/board (simplified for now)
    collection_name = f"{subject.lower()}_board" 
    try:
        collection = chroma_client.get_collection(name=collection_name)
        results = collection.query(
            query_texts=[query],
            n_results=1
        )
        if results['documents']:
            return results['documents'][0][0]
    except Exception:
        return None
    return None
