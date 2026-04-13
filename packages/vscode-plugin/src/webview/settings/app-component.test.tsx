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

const sampleConfig = {
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
};

/**
 * Query all <vscode-textfield> elements, returning [element, value] tuples.
 * Useful since vscode-label/vscode-textfield don't support getByLabelText in jsdom.
 */
const getTextfieldValues = (container: HTMLElement): ReadonlyArray<string> =>
  Array.from(container.querySelectorAll("vscode-textfield")).map((el) => el.getAttribute("value") ?? "");

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

  it("renders title and tab headers", () => {
    renderWithProvider(<SettingsApp />);
    expect(screen.getByText("indexion Settings")).toBeInTheDocument();
    expect(screen.getByText("Local (.indexion/)")).toBeInTheDocument();
    expect(screen.getByText("Global")).toBeInTheDocument();
  });

  it("populates fields when configLoaded received", () => {
    const { container } = renderWithProvider(<SettingsApp />);
    postFromHost({ type: "configLoaded", ...sampleConfig });
    // Local tab is active by default; first vscode-tab-panel contains local config
    const panels = container.querySelectorAll("vscode-tab-panel");
    const localPanel = panels[0];
    const values = getTextfieldValues(localPanel as HTMLElement);
    // The 3rd textfield is threshold (after binaryPath and specsDir)
    expect(values[2]).toBe("0.9");
  });

  it("sends save message with correct scope for local tab", () => {
    const { container } = renderWithProvider(<SettingsApp />);
    postFromHost({ type: "configLoaded", ...sampleConfig });
    resetMessages();
    // Click the first Save button (local tab panel)
    const saveButtons = container.querySelectorAll("vscode-button");
    const localSave = Array.from(saveButtons).find((el) => el.textContent?.trim() === "Save");
    expect(localSave).toBeDefined();
    fireEvent.click(localSave!);
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
