/**
 * @file Tests for the refactor checklist component.
 */

import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { RefactorChecklist } from "./refactor-checklist.tsx";

const makeItems = (count: number) =>
  Array.from({ length: count }, (_, i) => ({
    id: `item-${i}`,
    text: `Refactor item ${i}`,
    files: [`src/file-${i}.ts`],
    severity: (["high", "medium", "low"] as const)[i % 3],
  }));

describe("RefactorChecklist", () => {
  it("shows empty message when no items", () => {
    render(<RefactorChecklist items={[]} />);
    expect(screen.getByText("No refactoring items found")).toBeInTheDocument();
  });

  it("renders all items with severity badges", () => {
    const items = makeItems(3);
    render(<RefactorChecklist items={items} />);
    expect(screen.getByText("[high]")).toBeInTheDocument();
    expect(screen.getByText("[medium]")).toBeInTheDocument();
    expect(screen.getByText("[low]")).toBeInTheDocument();
    expect(screen.getByText("Refactor item 0")).toBeInTheDocument();
    expect(screen.getByText("Refactor item 1")).toBeInTheDocument();
    expect(screen.getByText("Refactor item 2")).toBeInTheDocument();
  });

  it("shows progress bar with 0/N initially", () => {
    render(<RefactorChecklist items={makeItems(5)} />);
    expect(screen.getByText("0/5 completed")).toBeInTheDocument();
  });

  it("updates progress when items are checked", () => {
    render(<RefactorChecklist items={makeItems(3)} />);
    const checkboxes = screen.getAllByRole("checkbox");
    fireEvent.click(checkboxes[0]);
    expect(screen.getByText("1/3 completed")).toBeInTheDocument();
    fireEvent.click(checkboxes[1]);
    expect(screen.getByText("2/3 completed")).toBeInTheDocument();
  });

  it("unchecks item when clicked again", () => {
    render(<RefactorChecklist items={makeItems(2)} />);
    const checkboxes = screen.getAllByRole("checkbox");
    fireEvent.click(checkboxes[0]);
    expect(screen.getByText("1/2 completed")).toBeInTheDocument();
    fireEvent.click(checkboxes[0]);
    expect(screen.getByText("0/2 completed")).toBeInTheDocument();
  });

  it("renders file links and calls onFileClick", () => {
    const onFileClick = vi.fn();
    render(<RefactorChecklist items={makeItems(1)} onFileClick={onFileClick} />);
    const fileLink = screen.getByText("src/file-0.ts");
    fireEvent.click(fileLink);
    expect(onFileClick).toHaveBeenCalledWith("src/file-0.ts");
  });
});
