import httpx
from core.config import get_settings

settings = get_settings()

YOUTUBE_SEARCH_URL = "https://www.googleapis.com/youtube/v3/search"


async def search_video(query: str) -> dict | None:
    if not settings.YOUTUBE_API_KEY:
        return None

    params = {
        "part": "snippet",
        "q": f"{query} educational explanation",
        "type": "video",
        "maxResults": 1,
        "key": settings.YOUTUBE_API_KEY,
        "safeSearch": "strict",
        "relevanceLanguage": "en",
    }

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(YOUTUBE_SEARCH_URL, params=params)
        if resp.status_code != 200:
            return None

        data = resp.json()
        items = data.get("items", [])
        if not items:
            return None

        item = items[0]
        return {
            "video_id": item["id"]["videoId"],
            "title": item["snippet"]["title"],
            "thumbnail_url": item["snippet"]["thumbnails"]["high"]["url"],
        }
