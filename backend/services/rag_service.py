import logging
import chromadb
from core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()
chroma_client = chromadb.PersistentClient(path=settings.CHROMA_DB_PATH)

VALID_BOARDS = {"cbse", "icse", "state"}


async def search_textbook(query: str, board: str) -> str | None:
    """Search the board-specific ChromaDB collection for the most relevant chunk."""
    collection_name = board.lower()
    if collection_name not in VALID_BOARDS:
        logger.warning(f"Unknown board '{board}' — skipping RAG search.")
        return None
    try:
        collection = chroma_client.get_collection(name=collection_name)
        results = collection.query(query_texts=[query], n_results=1)
        docs = results.get("documents", [])
        if docs and docs[0]:
            return docs[0][0]
    except Exception as e:
        logger.warning(f"RAG search failed for board '{board}': {e}")
    return None


async def ingest_textbook(text: str, board: str, filename: str) -> int:
    """Split text into 500-char chunks and store in the board-specific ChromaDB collection.

    Returns the number of chunks ingested.
    """
    collection_name = board.lower()
    if collection_name not in VALID_BOARDS:
        raise ValueError(f"Invalid board '{board}'. Must be one of: {VALID_BOARDS}")

    if not text or not text.strip():
        raise ValueError("No text content to ingest — the PDF appears to be empty.")

    # Split into 500-character chunks (non-overlapping)
    chunk_size = 500
    chunks = [text[i : i + chunk_size] for i in range(0, len(text), chunk_size)]
    # Filter out whitespace-only chunks
    chunks = [c for c in chunks if c.strip()]

    if not chunks:
        raise ValueError("Text produced zero non-empty chunks after splitting.")

    # Get or create the board collection (uses ChromaDB default embedding)
    collection = chroma_client.get_or_create_collection(name=collection_name)

    # Build unique IDs using filename + chunk index to allow re-ingestion
    ids = [f"{filename}__chunk_{i}" for i in range(len(chunks))]

    # Upsert so re-uploading the same file replaces old chunks
    collection.upsert(documents=chunks, ids=ids)

    logger.info(f"Ingested {len(chunks)} chunks from '{filename}' into '{collection_name}' collection.")
    return len(chunks)
