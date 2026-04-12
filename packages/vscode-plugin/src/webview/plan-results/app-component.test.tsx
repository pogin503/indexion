/**
 * @file Tests for the plan-results webview app component.
 */

import React from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import { WebviewProvider } from "../bridge/context.tsx";
import { postedMessages, resetMessages } from "../test-setup.ts";

const postFromHost = (data: unknown): void => {
  act(() => {
    window.dispatchEvent(new MessageEvent("message", { data }));
  });
};

const renderWithProvider = (ui: React.ReactElement) => render(<WebviewProvider>{ui}</WebviewProvider>);

let App: React.FC;

beforeAll(async () => {
  const mod = await import("./app-component.tsx");
  App = mod.PlanResultsApp;
});

beforeEach(() => {
  resetMessages();
});

describe("PlanResultsApp", () => {
  it("shows loading state initially", () => {
    renderWithProvider(<App />);
    expect(screen.getByText("Loading results...")).toBeInTheDocument();
  });

  it("renders markdown result when message received", () => {
    renderWithProvider(<App />);
    postFromHost({
      type: "resultLoaded",
      title: "Refactor Plan",
      content: "## Summary\nFound 3 duplicates",
      format: "markdown",
    });
    expect(screen.getByText("Refactor Plan")).toBeInTheDocument();
    expect(screen.getByText("## Summary")).toBeInTheDocument();
    expect(screen.getByText("Found 3 duplicates")).toBeInTheDocument();
  });

  it("renders JSON result in a code block", () => {
    renderWithProvider(<App />);
    postFromHost({
      type: "resultLoaded",
      title: "JSON Output",
      content: '{"count": 5}',
      format: "json",
    });
    expect(screen.getByText('{"count": 5}')).toBeInTheDocument();
    const pre = screen.getByText('{"count": 5}').closest("pre");
    expect(pre).toBeInTheDocument();
  });

  it("posts copyContent message when copy button clicked", () => {
    renderWithProvider(<App />);
    postFromHost({
      type: "resultLoaded",
      title: "Test",
      content: "content",
      format: "markdown",
    });
    fireEvent.click(screen.getByText("Copy"));
    expect(postedMessages).toContainEqual({ type: "copyContent" });
  });

  it("posts openFile message when file link clicked", () => {
    renderWithProvider(<App />);
    postFromHost({
      type: "resultLoaded",
      title: "Test",
      content: "Check `src/main.ts` for details",
      format: "markdown",
    });
    fireEvent.click(screen.getByText("src/main.ts"));
    expect(postedMessages).toContainEqual({ type: "openFile", filePath: "src/main.ts" });
  });
});
