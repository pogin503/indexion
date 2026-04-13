/**
 * @file SSE (Server-Sent Events) streaming client for indexion serve.
 *
 * Consumes `text/event-stream` responses from `/api/.../stream` endpoints.
 * Each SSE event line is `data: {json}\n\n`.
 */

/** SSE event types emitted by the server. */
export type SseEvent =
  | { readonly type: "progress"; readonly phase: string; readonly detail: string }
  | { readonly type: "item"; readonly data: unknown }
  | { readonly type: "items"; readonly data: ReadonlyArray<unknown> }
  | { readonly type: "result"; readonly data: unknown }
  | { readonly type: "done"; readonly total: number }
  | { readonly type: "error"; readonly message: string };

/** Options for streaming POST request. */
export type StreamPostOptions = {
  readonly body: unknown;
  readonly signal?: AbortSignal;
  readonly onEvent: (event: SseEvent) => void;
};

/**
 * POST to a streaming SSE endpoint and invoke onEvent for each parsed event.
 *
 * @param baseUrl  The base URL for the API (e.g. "http://127.0.0.1:3741/api").
 * @param path     The endpoint path (e.g. "/search/stream").
 * @param options  Request body, abort signal, and event callback.
 */
export const postStream = async (
  baseUrl: string,
  path: string,
  options: StreamPostOptions,
): Promise<void> => {
  const res = await fetch(`${baseUrl}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(options.body),
    signal: options.signal,
  });

  if (!res.ok) {
    options.onEvent({ type: "error", message: `HTTP ${res.status}: ${res.statusText}` });
    return;
  }

  const reader = res.body?.getReader();
  if (!reader) {
    options.onEvent({ type: "error", message: "No response body" });
    return;
  }

  const decoder = new TextDecoder();
  let buffer = "";

  for (;;) {
    const { done, value } = await reader.read();
    if (done) {
      break;
    }

    buffer += decoder.decode(value, { stream: true });

    // SSE events are separated by double newlines.
    // Each event line starts with "data: ".
    let boundary = buffer.indexOf("\n\n");
    while (boundary !== -1) {
      const chunk = buffer.slice(0, boundary);
      buffer = buffer.slice(boundary + 2);

      for (const line of chunk.split("\n")) {
        if (line.startsWith("data: ")) {
          const jsonStr = line.slice(6);
          try {
            const event = JSON.parse(jsonStr) as SseEvent;
            options.onEvent(event);
          } catch {
            // Skip malformed JSON lines
          }
        }
      }

      boundary = buffer.indexOf("\n\n");
    }
  }
};
