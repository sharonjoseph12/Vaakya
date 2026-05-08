# Requirements Document

## Introduction

VoiceGuru is a voice-first EdTech application for Indian school children following CBSE, ICSE, and State board curricula. This document covers the backend-ai branch (`feat/backend-ai`), which is responsible for the FastAPI server, AI services (Gemini 2.0 Flash), Retrieval-Augmented Generation (RAG) via ChromaDB, Supabase database integration, quiz generation and adaptive difficulty, weekly WhatsApp parent reports, and YouTube video search.

The backend must be production-ready: all endpoints must return graceful fallback responses on error, AI output must be TTS-friendly (no markdown), RAG must be board-specific, and the vision endpoint must never solve homework problems.

---

## Glossary

- **System**: The VoiceGuru FastAPI backend application.
- **AI_Service**: The module responsible for generating text and vision responses using Gemini 2.0 Flash.
- **RAG_Service**: The module responsible for ChromaDB-based textbook retrieval and ingestion.
- **DB_Service**: The module responsible for all Supabase CRUD operations.
- **Quiz_Service**: The module responsible for generating and evaluating MCQ quizzes with adaptive difficulty.
- **Report_Service**: The module responsible for generating and sending weekly WhatsApp summaries to parents via Twilio.
- **YouTube_Service**: The module responsible for searching educational videos via the YouTube Data API v3.
- **Config**: The Pydantic Settings module that loads environment variables from `.env`.
- **Supabase_Client**: The singleton Supabase Python client used for all database operations.
- **ChromaDB**: The persistent vector database used to store and retrieve textbook content.
- **Learner_Level**: A child's current difficulty tier — one of `Beginner`, `Intermediate`, or `Advanced`.
- **Board**: The Indian school curriculum board — one of `cbse`, `icse`, or `state`.
- **TTS-friendly**: Text output that contains no markdown syntax, no asterisks, no bullet points, and no special formatting characters, suitable for direct text-to-speech rendering.
- **Socratic hint**: A pedagogical hint that guides a student toward an answer without revealing the solution.
- **APScheduler**: The background task scheduler used to trigger the weekly report cron job.
- **Twilio**: The third-party SMS/WhatsApp messaging service used to deliver parent reports.

---

## Requirements

### Requirement 1: Application Bootstrap and Lifecycle

**User Story:** As a developer, I want the FastAPI application to start up cleanly, register all routers, and schedule background jobs, so that all API endpoints and cron tasks are available immediately after launch.

#### Acceptance Criteria

1. THE System SHALL expose a FastAPI application instance with title "VoiceGuru API" and version "1.0.0".
2. WHEN the application starts, THE System SHALL register routers for chat, vision, admin, quiz, and media endpoints under their respective URL prefixes.
3. WHEN the application starts, THE System SHALL schedule the `send_weekly_reports` job via APScheduler to run every Sunday at 18:00 IST (12:30 UTC).
4. WHEN the application shuts down, THE System SHALL gracefully stop the APScheduler without raising exceptions.
5. THE System SHALL serve a health-check response at `GET /` returning a JSON object confirming the backend is online.

---

### Requirement 2: Configuration Management

**User Story:** As a developer, I want all secrets and configuration values loaded from a `.env` file using Pydantic Settings, so that the application is configurable across environments without code changes.

#### Acceptance Criteria

1. THE Config SHALL load `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and `GEMINI_API_KEY` as required string fields from the environment.
2. THE Config SHALL load `CHROMA_DB_PATH` with a default value of `"./chroma_db"` when not set in the environment.
3. THE Config SHALL load `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_WHATSAPP_FROM` as optional string fields defaulting to empty string when not set.
4. THE Config SHALL load `YOUTUBE_API_KEY` as an optional string field defaulting to empty string when not set.
5. WHEN the application initialises, THE Config SHALL be loaded exactly once and cached for the lifetime of the process.
6. IF a required configuration field is absent from the environment, THEN THE System SHALL raise a startup error before accepting any requests.

---

### Requirement 3: Supabase Client Initialisation

**User Story:** As a developer, I want a singleton Supabase client initialised with the service role key, so that all backend services share one authenticated database connection.

#### Acceptance Criteria

1. THE Supabase_Client SHALL be initialised using `supabase.create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)`.
2. THE Supabase_Client SHALL be created at most once per process lifetime (singleton pattern).
3. WHEN any service calls `get_supabase()`, THE Supabase_Client SHALL return the existing instance if already initialised.
4. THE Supabase_Client SHALL use the service role key, not the anon key, to bypass Row Level Security for backend operations.

---

### Requirement 4: Pydantic Request and Response Schemas

**User Story:** As a developer, I want all API request and response bodies defined as Pydantic models, so that input validation and serialisation are handled automatically.

#### Acceptance Criteria

1. THE System SHALL define a `ChatRequest` schema with fields: `profile_id` (str), `query` (str, max 500 characters), `subject` (str), `language` (str), and `learner_level` (str).
2. THE System SHALL define a `ChatResponse` schema with fields: `ai_reply` (str), `source_textbook_page` (optional str), and `status` (str).
3. THE System SHALL define a `QuizGenerateRequest` schema with fields: `child_id` (str) and `subject` (str).
4. THE System SHALL define a `QuizQuestion` schema with fields: `question` (str), `options` (list of str), and `correct_answer` (str).
5. THE System SHALL define a `QuizGenerateResponse` schema with fields: `questions` (list of `QuizQuestion`) and `status` (str).
6. THE System SHALL define a `QuizSubmitRequest` schema with fields: `child_id` (str), `subject` (str), and `score` (int, constrained to 0–3 inclusive).
7. THE System SHALL define a `QuizSubmitResponse` schema with fields: `previous_level` (str), `new_level` (str), `message` (str), and `status` (str).
8. THE System SHALL define a `VideoResponse` schema with fields: `video_id` (str), `title` (str), `thumbnail_url` (str), and `status` (str).
9. WHEN a request body fails Pydantic validation, THE System SHALL return an HTTP 422 response with field-level error details.

---

### Requirement 5: AI Text Response Generation

**User Story:** As a student, I want the AI tutor to answer my questions using only my textbook content, in plain spoken language, so that the answer is accurate to my syllabus and readable by a TTS engine.

#### Acceptance Criteria

1. WHEN `generate_response(query, context, learner_level, language)` is called, THE AI_Service SHALL send a prompt to Gemini 2.0 Flash that includes the textbook context, the learner level, and the target language.
2. THE AI_Service SHALL instruct Gemini to answer using only the provided textbook context and not use outside knowledge.
3. THE AI_Service SHALL instruct Gemini to produce output that is TTS-friendly: no markdown, no asterisks, no bullet points, and no special formatting characters.
4. THE AI_Service SHALL instruct Gemini to limit the response to a maximum of 4 short sentences.
5. WHEN the textbook context is empty or unavailable, THE AI_Service SHALL instruct Gemini to respond with a syllabus-boundary message in the requested language rather than hallucinating an answer.
6. THE AI_Service SHALL use the `gemini-2.0-flash` model for all text generation calls.

---

### Requirement 6: AI Vision Hint Generation

**User Story:** As a student, I want to photograph a homework problem and receive a Socratic hint, so that I am guided to think through the problem myself rather than being given the answer.

#### Acceptance Criteria

1. THE AI_Service SHALL expose a `generate_vision_hint(image_bytes)` function that accepts raw image bytes and returns a text hint.
2. WHEN `generate_vision_hint` is called, THE AI_Service SHALL send the image bytes to Gemini 2.0 Flash with a Socratic system prompt.
3. THE AI_Service SHALL instruct Gemini to never reveal the solution to the homework problem.
4. THE AI_Service SHALL instruct Gemini to provide exactly one hint in a maximum of 3 sentences.
5. THE AI_Service SHALL instruct Gemini to produce TTS-friendly output with no markdown or special formatting.

---

### Requirement 7: Database Service — Child Profile and Chat Logs

**User Story:** As a developer, I want a database service layer that abstracts all Supabase operations, so that routers and other services interact with the database through a clean, testable interface.

#### Acceptance Criteria

1. WHEN `get_child_profile(profile_id)` is called, THE DB_Service SHALL query the `children` table for the row matching `id = profile_id` and return the row data.
2. WHEN `save_chat_log(child_id, query, ai_reply, subject, language, source_page)` is called, THE DB_Service SHALL insert a new row into the `chat_logs` table with all provided fields.
3. WHEN `get_weekly_logs(child_id)` is called, THE DB_Service SHALL query the `chat_logs` table for all rows where `child_id` matches and `created_at` is within the last 7 days, and return the list of rows.
4. WHEN `update_learner_level(child_id, level)` is called, THE DB_Service SHALL update the `learner_level` field on the matching row in the `children` table.
5. THE DB_Service SHALL use the Supabase_Client singleton for all database operations.

---

### Requirement 8: RAG Service — Board-Specific Textbook Search

**User Story:** As a student, I want the AI to retrieve context from my specific board's textbook, so that answers are accurate to my curriculum and not mixed with content from other boards.

#### Acceptance Criteria

1. WHEN `search_textbook(query, board)` is called, THE RAG_Service SHALL query the ChromaDB collection named after the board value (e.g., `cbse`, `icse`, or `state`).
2. THE RAG_Service SHALL use the `board` parameter — not the `subject` parameter — as the ChromaDB collection name.
3. WHEN `search_textbook` is called, THE RAG_Service SHALL return the single most relevant document chunk (top-1 result).
4. IF the specified board collection does not exist in ChromaDB, THEN THE RAG_Service SHALL return `None` without raising an unhandled exception.
5. WHEN `ingest_textbook(file_bytes, board, filename)` is called, THE RAG_Service SHALL split the text content into chunks of at most 500 characters.
6. WHEN `ingest_textbook` is called, THE RAG_Service SHALL store all chunks in the ChromaDB collection named after the `board` parameter.
7. WHEN `ingest_textbook` is called, THE RAG_Service SHALL use ChromaDB's default embedding function to embed each chunk before storage.
8. THE RAG_Service SHALL use a `chromadb.PersistentClient` initialised with the path from `Config.CHROMA_DB_PATH`.

---

### Requirement 9: Chat Endpoint

**User Story:** As a student, I want to ask a question via the chat API and always receive a meaningful response, so that the app never crashes or shows a technical error to me.

#### Acceptance Criteria

1. THE System SHALL expose `POST /api/v1/chat/ask` accepting a `ChatRequest` body and returning a `ChatResponse`.
2. WHEN a valid `ChatRequest` is received, THE System SHALL call `search_textbook` with the query and the child's board to retrieve textbook context.
3. WHEN a valid `ChatRequest` is received, THE System SHALL call `generate_response` with the query, retrieved context, learner level, and language.
4. WHEN a valid `ChatRequest` is received, THE System SHALL call `save_chat_log` to persist the query and AI reply to Supabase.
5. WHEN all steps succeed, THE System SHALL return a `ChatResponse` with `status = "success"` and the AI-generated reply.
6. IF any exception occurs during the chat pipeline, THEN THE System SHALL return a `ChatResponse` with a user-friendly fallback message and `status = "error"` rather than propagating an HTTP 500 error to the client.

---

### Requirement 10: Vision Endpoint

**User Story:** As a student, I want to upload a photo of my homework and receive a hint, so that I can get help without the app giving me the answer directly.

#### Acceptance Criteria

1. THE System SHALL expose `POST /api/v1/chat/vision` accepting a multipart file upload and returning a response containing an `ai_reply` and `status`.
2. WHEN a valid image file is uploaded, THE System SHALL read the file bytes and pass them to `generate_vision_hint`.
3. WHEN `generate_vision_hint` returns successfully, THE System SHALL return the hint text with `status = "success"`.
4. IF any exception occurs during vision processing, THEN THE System SHALL return the fallback message `"I can't quite read that image. Can you take a sharper photo?"` with `status = "error"` rather than propagating an HTTP 500 error.

---

### Requirement 11: Admin PDF Ingestion Endpoint

**User Story:** As an administrator, I want to upload a PDF textbook and have its content indexed into ChromaDB, so that students can receive RAG-augmented answers from their actual syllabus material.

#### Acceptance Criteria

1. THE System SHALL expose `POST /api/v1/admin/upload-pdf` accepting a multipart PDF file upload and a `board` query parameter.
2. WHEN a PDF file is uploaded, THE System SHALL extract all text from the PDF using PyPDF2.
3. WHEN text extraction succeeds, THE System SHALL call `ingest_textbook(file_bytes, board, filename)` to store the content in ChromaDB.
4. WHEN ingestion succeeds, THE System SHALL return a JSON response confirming the filename and the number of chunks ingested.
5. IF the uploaded file cannot be parsed as a PDF, THEN THE System SHALL return an HTTP 400 response with a descriptive error message.
6. IF any exception occurs during ingestion, THEN THE System SHALL return an HTTP 500 response with a descriptive error message rather than an unhandled traceback.

---

### Requirement 12: Quiz Generation

**User Story:** As a student, I want to receive quiz questions matched to my current learning level and subject, so that the quiz is neither too easy nor too hard for me.

#### Acceptance Criteria

1. THE System SHALL expose `POST /api/v1/quiz/generate` accepting a `QuizGenerateRequest` body and returning a `QuizGenerateResponse`.
2. WHEN `generate_quiz(child_id, subject)` is called, THE Quiz_Service SHALL fetch the child's `learner_level` from Supabase via `get_child_profile`.
3. WHEN `generate_quiz` is called, THE Quiz_Service SHALL prompt Gemini 2.0 Flash to generate exactly 3 MCQ questions appropriate for the child's `learner_level` and `subject`.
4. THE Quiz_Service SHALL instruct Gemini to return a JSON array with no markdown or code fences, where each element contains `question` (str), `options` (list of 4 strings), and `correct_answer` (one of A, B, C, D).
5. WHEN Gemini returns a response wrapped in markdown code fences, THE Quiz_Service SHALL strip the fences before parsing the JSON.
6. WHEN quiz generation succeeds, THE System SHALL return a `QuizGenerateResponse` with `status = "success"` and the parsed questions.
7. IF any exception occurs during quiz generation, THEN THE System SHALL return a `QuizGenerateResponse` with an empty questions list and `status = "error"`.

---

### Requirement 13: Quiz Submission and Adaptive Difficulty

**User Story:** As a student, I want my quiz score to automatically adjust my learning level, so that future questions and AI explanations are calibrated to my demonstrated ability.

#### Acceptance Criteria

1. THE System SHALL expose `POST /api/v1/quiz/submit` accepting a `QuizSubmitRequest` body and returning a `QuizSubmitResponse`.
2. WHEN `evaluate_quiz(child_id, subject, score)` is called, THE Quiz_Service SHALL fetch the child's current `learner_level` from Supabase.
3. WHEN the score is 3 out of 3, THE Quiz_Service SHALL set the new `learner_level` to `"Advanced"`.
4. WHEN the score is 1 or fewer out of 3, THE Quiz_Service SHALL set the new `learner_level` to `"Beginner"`.
5. WHEN the score is 2 out of 3, THE Quiz_Service SHALL leave the `learner_level` unchanged.
6. WHEN the new `learner_level` differs from the previous level, THE Quiz_Service SHALL call `update_learner_level` to persist the change to Supabase.
7. WHEN the new `learner_level` is the same as the previous level, THE Quiz_Service SHALL NOT call `update_learner_level`.
8. THE Quiz_Service SHALL insert a row into the `quiz_results` table recording `child_id`, `subject`, `score`, `total` (3), `difficulty_before`, and `difficulty_after`.
9. WHEN quiz evaluation succeeds, THE System SHALL return a `QuizSubmitResponse` with `status = "success"`, the previous level, the new level, and a contextual message.
10. IF any exception occurs during quiz evaluation, THEN THE System SHALL return a `QuizSubmitResponse` with `status = "error"` and a user-friendly message rather than propagating an HTTP 500 error.

---

### Requirement 14: Weekly Parent Report via WhatsApp

**User Story:** As a parent, I want to receive a weekly WhatsApp summary of my child's learning activity, so that I can stay informed about their progress without logging into the app.

#### Acceptance Criteria

1. WHEN the APScheduler cron fires every Sunday at 12:30 UTC, THE Report_Service SHALL execute `send_weekly_reports()`.
2. WHEN `send_weekly_reports` is called, THE Report_Service SHALL fetch all children from the `children` table.
3. FOR each child, THE Report_Service SHALL fetch all `chat_logs` rows from the last 7 days.
4. IF a child has no chat logs in the last 7 days, THEN THE Report_Service SHALL skip that child without raising an exception.
5. FOR each child with logs, THE Report_Service SHALL fetch the parent's phone number from the `parents` table using `parent_id`.
6. IF a parent record is missing or has no phone number, THEN THE Report_Service SHALL skip that child without raising an exception.
7. WHEN logs and a phone number are available, THE Report_Service SHALL prompt Gemini to generate a 3-sentence professional and encouraging summary of the child's weekly activity.
8. WHEN the summary is generated, THE Report_Service SHALL send it via Twilio to the parent's WhatsApp number prefixed with `"whatsapp:"`.
9. IF Twilio credentials are not configured, THEN THE Report_Service SHALL log a warning and return without attempting to send any messages.
10. IF sending a report for one child fails, THEN THE Report_Service SHALL log the error and continue processing the remaining children.

---

### Requirement 15: YouTube Video Search

**User Story:** As a student, I want to find an educational video related to my question, so that I can supplement the AI text answer with a visual explanation.

#### Acceptance Criteria

1. THE System SHALL expose `GET /api/v1/media/video?query=...` accepting a `query` string parameter and returning a `VideoResponse`.
2. WHEN `search_video(query)` is called, THE YouTube_Service SHALL call the YouTube Data API v3 search endpoint with `safeSearch=strict`, `type=video`, and `maxResults=1`.
3. WHEN the API returns at least one result, THE YouTube_Service SHALL return a dict containing `video_id`, `title`, and `thumbnail_url` from the first result.
4. WHEN the YouTube API returns no results, THE YouTube_Service SHALL return `None`.
5. IF `YOUTUBE_API_KEY` is not configured, THEN THE YouTube_Service SHALL return `None` without making an HTTP request.
6. WHEN `search_video` returns `None`, THE System SHALL return a `VideoResponse` with `status = "not_found"` and empty string fields.
7. IF any exception occurs during video search, THEN THE System SHALL return a `VideoResponse` with `status = "error"` rather than propagating an HTTP 500 error.

---

## Non-Functional Requirements

### Requirement 16: Resilience and Error Containment

**User Story:** As a product owner, I want every API endpoint to return a structured response even when internal errors occur, so that the mobile app never receives an unhandled 500 error that could crash the user experience.

#### Acceptance Criteria

1. THE System SHALL catch all unhandled exceptions at the router level for every endpoint and return a structured fallback response with an appropriate `status` field.
2. THE System SHALL never propagate a raw Python traceback or HTTP 500 response to API clients.
3. WHEN an internal service call fails, THE System SHALL log the error for observability before returning the fallback response.

---

### Requirement 17: TTS Output Compliance

**User Story:** As a student using the voice interface, I want all AI-generated text to be readable by a TTS engine without any formatting artefacts, so that the spoken output sounds natural.

#### Acceptance Criteria

1. THE AI_Service SHALL produce responses that contain no markdown syntax characters (no `*`, `**`, `#`, `-`, `` ` ``, `_`).
2. THE AI_Service SHALL produce responses that contain no bullet points or numbered list formatting.
3. THE AI_Service SHALL produce responses that are limited to a maximum of 4 sentences for text responses and 3 sentences for vision hints.

---

### Requirement 18: Board-Specific RAG Isolation

**User Story:** As a student, I want the RAG system to only retrieve content from my board's textbooks, so that I never receive answers based on a different curriculum.

#### Acceptance Criteria

1. THE RAG_Service SHALL maintain separate ChromaDB collections for each board, named `cbse`, `icse`, and `state`.
2. THE RAG_Service SHALL never query a collection using a subject name as the collection identifier.
3. WHEN content is ingested for a board, THE RAG_Service SHALL store it exclusively in that board's collection.
