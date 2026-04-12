/**
 * @file Tests for the settings webview app component.
 */

import React from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import { WebviewProvider } from "../bridge/context.tsx";
import { postedMessages, resetMessages } from "../test-setup.ts";

const renderWithProvider = (ui: React.ReactElement) => render(<WebviewProvider>{ui}</WebviewProvider>);

const postFromHost = (data: unknown): void => {
  act(() => {
    window.dispatchEvent(new MessageEvent("message", { data }));
  });
};

let SettingsApp: React.FC;

beforeAll(async () => {
  const mod = await import("./app-component.tsx");
  SettingsApp = mod.SettingsApp;
});

beforeEach(() => {
  resetMessages();
});

describe("SettingsApp", () => {
  it("sends load message on mount", () => {
    renderWithProvider(<SettingsApp />);
    expect(postedMessages).toContainEqual({ type: "load" });
  });

  it("renders title and tabs", () => {
    renderWithProvider(<SettingsApp />);
    expect(screen.getByText("indexion Settings")).toBeInTheDocument();
    expect(screen.getByText("Local (.indexion/)")).toBeInTheDocument();
    expect(screen.getByText("Global")).toBeInTheDocument();
  });

  it("populates fields when configLoaded received", () => {
    renderWithProvider(<SettingsApp />);
    postFromHost({
      type: "configLoaded",
      global: {
        binaryPath: "/usr/bin/indexion",
        specsDir: "specs",
        defaultThreshold: 0.8,
        defaultStrategy: "hybrid",
        includes: [],
        excludes: [],
      },
      local: {
        binaryPath: "",
        specsDir: "kgfs",
        defaultThreshold: 0.9,
        defaultStrategy: "tfidf",
        includes: [],
        excludes: [],
      },
    });
    const thresholdInput = screen.getByLabelText("Default Threshold") as HTMLInputElement;
    expect(thresholdInput.value).toBe("0.9");
  });

  it("switches to global tab and shows global config", () => {
    renderWithProvider(<SettingsApp />);
    postFromHost({
      type: "configLoaded",
      global: {
        binaryPath: "/usr/bin/indexion",
        specsDir: "specs",
        defaultThreshold: 0.8,
        defaultStrategy: "hybrid",
        includes: [],
        excludes: [],
      },
      local: {
        binaryPath: "",
        specsDir: "kgfs",
        defaultThreshold: 0.9,
        defaultStrategy: "tfidf",
        includes: [],
        excludes: [],
      },
    });
    fireEvent.click(screen.getByText("Global"));
    const thresholdInput = screen.getByLabelText("Default Threshold") as HTMLInputElement;
    expect(thresholdInput.value).toBe("0.8");
  });

  it("sends save message with correct scope", () => {
    renderWithProvider(<SettingsApp />);
    postFromHost({
      type: "configLoaded",
      global: {
        binaryPath: "",
        specsDir: "kgfs",
        defaultThreshold: 0.7,
        defaultStrategy: "tfidf",
        includes: [],
        excludes: [],
      },
      local: {
        binaryPath: "",
        specsDir: "kgfs",
        defaultThreshold: 0.7,
        defaultStrategy: "tfidf",
        includes: [],
        excludes: [],
      },
    });
    resetMessages();
    fireEvent.click(screen.getByText("Save"));
    expect(postedMessages).toHaveLength(1);
    expect(postedMessages[0]).toMatchObject({ type: "save", scope: "local" });
  });

  it("shows save status message", () => {
    renderWithProvider(<SettingsApp />);
    postFromHost({ type: "saved", success: true, scope: "local" });
    expect(screen.getByText("Saved!")).toBeInTheDocument();
  });

  it("shows failure status message", () => {
    renderWithProvider(<SettingsApp />);
    postFromHost({ type: "saved", success: false, scope: "local" });
    expect(screen.getByText("Failed to save")).toBeInTheDocument();
  });
});
