import asyncio
import os
import argparse
from services.rag_service import ingest_text

async def main():
    parser = argparse.ArgumentParser(description="Ingest local textbooks into VoiceGuru ChromaDB")
    parser.add_argument("--dir", type=str, required=True, help="Directory containing the .txt files")
    parser.add_argument("--board", type=str, required=True, choices=["CBSE", "ICSE", "STATE"], help="Board classification")
    args = parser.parse_args()

    if not os.path.isdir(args.dir):
        print(f"Error: Directory '{args.dir}' does not exist.")
        return

    files = [f for f in os.listdir(args.dir) if f.endswith('.txt')]
    if not files:
        print(f"No .txt files found in {args.dir}")
        return

    print(f"Found {len(files)} textbooks to ingest for {args.board} board...")

    for filename in files:
        filepath = os.path.join(args.dir, filename)
        print(f"Ingesting: {filename}...")
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if not content.strip():
            print(f"  -> Skipping {filename}: File is empty")
            continue
            
        await ingest_text(content, args.board, filename)
        print(f"  -> Successfully ingested {filename}")

    print("\n✅ All files ingested into ChromaDB successfully!")

if __name__ == "__main__":
    asyncio.run(main())
