-- Sessions and Chunks Schema
-- This schema represents a chat session system with chunks, attachments, and various processing states

CREATE TABLE "sessions" ("id" text primary key, "user_id" text, "status" text not null, "created_at" text not null, "updated_at" text);

CREATE TABLE "chunks" ("id" text primary key, "session_id" text not null, "actor_type" text not null, "actor_user_id" text, "actor_name" text, "content" text not null, "status" text not null, "created_at" text not null, "updated_at" text, "title" text, constraint "chunks_session_id_fk" foreign key ("session_id") references "sessions" ("id") on delete cascade);

CREATE TABLE "session_chunks" ("session_id" text not null, "position" integer not null, "chunk_id" text not null, constraint "session_chunks_pk" primary key ("session_id", "position"), constraint "session_chunks_session_id_fk" foreign key ("session_id") references "sessions" ("id") on delete cascade, constraint "session_chunks_chunk_id_fk" foreign key ("chunk_id") references "chunks" ("id") on delete cascade);

CREATE TABLE "attachments" ("id" text primary key, "chunk_id" text not null, "kind" text not null, "uri" text not null, "description" text not null, "mime_type" text, "size_bytes" integer, "metadata_json" text, constraint "attachments_chunk_id_fk" foreign key ("chunk_id") references "chunks" ("id") on delete cascade);

CREATE TABLE "chunk_processing_states" ("chunk_id" text primary key, "state" text not null, "reason" text, "updated_at" text not null, constraint "chunk_processing_states_chunk_id_fk" foreign key ("chunk_id") references "chunks" ("id") on delete cascade);

CREATE TABLE "chunk_sources" ("chunk_id" text not null, "position" integer not null, "source_chunk_id" text not null, constraint "chunk_sources_pk" primary key ("chunk_id", "position"), constraint "chunk_sources_chunk_id_fk" foreign key ("chunk_id") references "chunks" ("id") on delete cascade, constraint "chunk_sources_source_chunk_id_fk" foreign key ("source_chunk_id") references "chunks" ("id") on delete cascade);

CREATE TABLE "chunk_tool_calls" ("chunk_id" text not null, "index" integer not null, "tool_call_id" text not null, "name" text not null, "input_json" text not null, "output_json" text, constraint "chunk_tool_calls_pk" primary key ("chunk_id", "index"), constraint "chunk_tool_calls_chunk_id_fk" foreign key ("chunk_id") references "chunks" ("id") on delete cascade);

CREATE TABLE "recall_indexes" ("id" text primary key, "chunk_id" text not null, "view_key" text not null, "title" text, "detail" text, "summary" text, "embedding_json" text not null, "is_main" integer not null, constraint "recall_indexes_chunk_id_fk" foreign key ("chunk_id") references "chunks" ("id") on delete cascade);

CREATE TABLE "segmentation_jobs" ("id" text primary key, "session_id" text not null, "status" text not null, "total_chunks" integer not null, "window_config" text not null, "checkpoint" text not null, "error" text, "created_at" text not null, "updated_at" text not null, constraint "segmentation_jobs_session_id_fk" foreign key ("session_id") references "sessions" ("id") on delete cascade);
