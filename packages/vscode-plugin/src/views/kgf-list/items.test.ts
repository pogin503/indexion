/**
 * @file Tests for KGF tree view items.
 */

import { TreeItemCollapsibleState } from "vscode";
import { toTreeItem, type KgfCategoryItem, type KgfSpecItem } from "./items.ts";

describe("toTreeItem", () => {
  it("creates expanded tree item for category", () => {
    const category: KgfCategoryItem = {
      type: "category",
      name: "programming",
      specs: [
        { name: "typescript", sources: [".ts", ".tsx"], category: "programming" },
        { name: "python", sources: [".py"], category: "programming" },
      ],
    };
    const item = toTreeItem(category);
    expect(item.label).toBe("programming");
    expect(item.collapsibleState).toBe(TreeItemCollapsibleState.Expanded);
    expect(item.description).toBe("2 specs");
  });

  it("creates leaf tree item for spec", () => {
    const spec: KgfSpecItem = {
      type: "spec",
      spec: { name: "python", sources: [".py", ".pyw"], category: "programming" },
    };
    const item = toTreeItem(spec);
    expect(item.label).toBe("python");
    expect(item.collapsibleState).toBe(TreeItemCollapsibleState.None);
    expect(item.description).toBe(".py, .pyw");
    expect(item.contextValue).toBe("kgfSpec");
    expect(item.command?.command).toBe("indexion.kgfInspect");
    expect(item.command?.arguments).toEqual(["python"]);
  });
});
