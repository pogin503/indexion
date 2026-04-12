/**
 * @file Tests for the WebviewView handshake protocol.
 *
 * Verifies that:
 * - Messages sent before "ready" are queued, not lost
 * - Messages sent before attach are discarded
 * - onReady fires exactly once
 * - Queued messages are flushed in order after "ready"
 * - Messages sent after "ready" are delivered immediately
 */

import { describe, it, expect, vi } from "vitest";
import { createWebviewBridge } from "./webview-bridge.ts";

type TestMessage = { readonly type: string; readonly data?: string };

/** Create a mock WebviewView that records postMessage calls. */
const createMockView = () => {
  const posted: Array<unknown> = [];

  let messageHandler: ((msg: { type: string }) => void) | undefined;

  const view = {
    webview: {
      postMessage: vi.fn((msg: unknown) => {
        posted.push(msg);
        return true;
      }),
      onDidReceiveMessage: (handler: (msg: { type: string }) => void) => {
        messageHandler = handler;
        return { dispose: () => {} };
      },
      options: {},
      html: "",
      asWebviewUri: (uri: unknown) => uri,
    },
  } as unknown as import("vscode").WebviewView;

  /** Simulate the React app sending a message to the provider. */
  const simulateMessage = (msg: { type: string }): void => {
    messageHandler?.(msg);
  };

  return { view, posted, simulateMessage };
};

describe("createWebviewBridge", () => {
  it("discards messages when not attached", () => {
    const bridge = createWebviewBridge<TestMessage>();
    bridge.post({ type: "hello" });
    expect(bridge.isAttached()).toBe(false);
    expect(bridge.isReady()).toBe(false);
  });

  it("queues messages sent before ready", () => {
    const bridge = createWebviewBridge<TestMessage>();
    const { view, posted } = createMockView();

    bridge.attach(view, () => {});
    expect(bridge.isAttached()).toBe(true);
    expect(bridge.isReady()).toBe(false);

    bridge.post({ type: "msg1" });
    bridge.post({ type: "msg2" });

    expect(posted).toHaveLength(0);
  });

  it("flushes queued messages on ready", () => {
    const bridge = createWebviewBridge<TestMessage>();
    const { view, posted, simulateMessage } = createMockView();

    bridge.attach(view, () => {});

    bridge.post({ type: "msg1", data: "first" });
    bridge.post({ type: "msg2", data: "second" });
    expect(posted).toHaveLength(0);

    simulateMessage({ type: "ready" });

    expect(bridge.isReady()).toBe(true);
    expect(posted).toHaveLength(2);
    expect(posted[0]).toEqual({ type: "msg1", data: "first" });
    expect(posted[1]).toEqual({ type: "msg2", data: "second" });
  });

  it("calls onReady exactly once", () => {
    const bridge = createWebviewBridge<TestMessage>();
    const { view, simulateMessage } = createMockView();
    const onReady = vi.fn();

    bridge.attach(view, onReady);

    simulateMessage({ type: "ready" });
    simulateMessage({ type: "ready" });

    expect(onReady).toHaveBeenCalledOnce();
  });

  it("delivers messages immediately after ready", () => {
    const bridge = createWebviewBridge<TestMessage>();
    const { view, posted, simulateMessage } = createMockView();

    bridge.attach(view, () => {});
    simulateMessage({ type: "ready" });

    bridge.post({ type: "after-ready" });
    expect(posted).toHaveLength(1);
    expect(posted[0]).toEqual({ type: "after-ready" });
  });

  it("onReady can post messages that are delivered immediately", () => {
    const bridge = createWebviewBridge<TestMessage>();
    const { view, posted, simulateMessage } = createMockView();

    bridge.attach(view, () => {
      bridge.post({ type: "init-from-onReady" });
    });

    bridge.post({ type: "queued-before" });

    simulateMessage({ type: "ready" });

    expect(posted).toHaveLength(2);
    expect(posted[0]).toEqual({ type: "init-from-onReady" });
    expect(posted[1]).toEqual({ type: "queued-before" });
  });

  it("resets state on re-attach", () => {
    const bridge = createWebviewBridge<TestMessage>();
    const mock1 = createMockView();
    const mock2 = createMockView();

    bridge.attach(mock1.view, () => {});
    mock1.simulateMessage({ type: "ready" });
    expect(bridge.isReady()).toBe(true);

    bridge.attach(mock2.view, () => {});
    expect(bridge.isReady()).toBe(false);

    bridge.post({ type: "for-view2" });
    expect(mock2.posted).toHaveLength(0);

    mock2.simulateMessage({ type: "ready" });
    expect(mock2.posted).toHaveLength(1);
    expect(mock2.posted[0]).toEqual({ type: "for-view2" });
  });

  it("ignores non-ready messages in handshake", () => {
    const bridge = createWebviewBridge<TestMessage>();
    const { view, posted, simulateMessage } = createMockView();
    const onReady = vi.fn();

    bridge.attach(view, onReady);
    bridge.post({ type: "queued" });

    simulateMessage({ type: "search" });
    simulateMessage({ type: "navigate" });

    expect(onReady).not.toHaveBeenCalled();
    expect(posted).toHaveLength(0);
    expect(bridge.isReady()).toBe(false);
  });
});
