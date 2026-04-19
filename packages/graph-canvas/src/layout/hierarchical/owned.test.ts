/**
 * @file Contract tests for owned-leaf placement.
 *
 * placeOwnedCloud is the function that turns "these leaves belong to
 * cluster X" into actual positions inside X's bubble. Two branches
 * to cover:
 *
 *   1. single-kind clusters → placeOwnedBall (dense ball, or packed
 *      fibonacci for n≤6)
 *   2. multi-kind clusters → placeOwnedByKind (radial bands)
 *
 * Both must keep every leaf inside the bubble and produce finite
 * coordinates.
 */

import { describe, expect, it } from "vitest";
import type { LayoutSettings, ViewNode } from "../../types.ts";
import { DEFAULT_RENDER_SETTINGS } from "../../renderer/settings.ts";
import { ORIGIN, type Vec3 } from "../geometry.ts";
import {
  groupByKind,
  hasInternalEdge,
  placeOwnedBall,
  placeOwnedByKind,
  placeOwnedCloud,
} from "./owned.ts";

const SETTINGS: LayoutSettings = DEFAULT_RENDER_SETTINGS.layout;

function mkNode(id: string, kind: string = "module"): ViewNode {
  return {
    id,
    label: id,
    kind,
    group: "",
    file: null,
    doc: null,
    metadata: {},
    x: 0,
    y: 0,
    z: 0,
    vx: 0,
    vy: 0,
    vz: 0,
    pinned: false,
  };
}

function radialDist(n: ViewNode, centre: Vec3): number {
  const dx = n.x - centre.x;
  const dy = n.y - centre.y;
  const dz = n.z - centre.z;
  return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

describe("groupByKind", () => {
  it("buckets by node.kind and sorts most-populous first", () => {
    const nodes = [
      mkNode("a1", "module"),
      mkNode("b", "function"),
      mkNode("a2", "module"),
      mkNode("c", "type"),
      mkNode("a3", "module"),
    ];
    const groups = groupByKind(nodes);
    expect(groups.length).toBe(3);
    expect(groups[0]!.length).toBe(3); // modules
    expect(groups[1]!.length).toBe(1);
    expect(groups[2]!.length).toBe(1);
  });

  it("returns a single group when every node has the same kind", () => {
    const nodes = [mkNode("a"), mkNode("b"), mkNode("c")];
    expect(groupByKind(nodes).length).toBe(1);
  });

  it("handles empty input", () => {
    expect(groupByKind([]).length).toBe(0);
  });
});

describe("hasInternalEdge", () => {
  it("true when at least one edge connects two members", () => {
    const nodes = [mkNode("a"), mkNode("b")];
    const edges = new Map<string, readonly string[]>([["a", ["b"]]]);
    expect(hasInternalEdge(nodes, edges)).toBe(true);
  });

  it("false when all neighbours are outside the member set", () => {
    const nodes = [mkNode("a"), mkNode("b")];
    const edges = new Map<string, readonly string[]>([["a", ["outside"]]]);
    expect(hasInternalEdge(nodes, edges)).toBe(false);
  });

  it("ignores self-loops", () => {
    const nodes = [mkNode("a")];
    const edges = new Map<string, readonly string[]>([["a", ["a"]]]);
    expect(hasInternalEdge(nodes, edges)).toBe(false);
  });

  it("false for empty member set", () => {
    expect(hasInternalEdge([], new Map())).toBe(false);
  });
});

describe("placeOwnedBall", () => {
  it("handles n=1 by writing centre", () => {
    const n = mkNode("a");
    placeOwnedBall({
      nodes: [n],
      centre: { x: 10, y: 20, z: 30 },
      maxRadius: 100,
      settings: SETTINGS,
    });
    expect(n.x).toBe(10);
    expect(n.y).toBe(20);
    expect(n.z).toBe(30);
  });

  it("places small clusters (n ≤ 6) on a tight fibonacci sphere", () => {
    // For n=5 all points land inside maxRadius × 0.85 (the clamp
    // used in the small-n branch).
    const nodes = [
      mkNode("a"),
      mkNode("b"),
      mkNode("c"),
      mkNode("d"),
      mkNode("e"),
    ];
    placeOwnedBall({
      nodes,
      centre: ORIGIN,
      maxRadius: 100,
      settings: SETTINGS,
    });
    for (const n of nodes) {
      expect(radialDist(n, ORIGIN)).toBeLessThanOrEqual(100 * 0.85 + 1e-6);
    }
  });

  it("places larger clusters (n > 6) inside a volumetric shell", () => {
    const nodes = Array.from({ length: 20 }, (_, i) => mkNode(`n-${i}`));
    placeOwnedBall({
      nodes,
      centre: ORIGIN,
      maxRadius: 100,
      settings: SETTINGS,
    });
    for (const n of nodes) {
      expect(radialDist(n, ORIGIN)).toBeLessThanOrEqual(100 * 0.92 + 1e-6);
    }
  });

  it("every coordinate is finite for any n", () => {
    for (const n of [1, 2, 6, 7, 20, 100]) {
      const nodes = Array.from({ length: n }, (_, i) => mkNode(`n-${i}`));
      placeOwnedBall({
        nodes,
        centre: ORIGIN,
        maxRadius: 100,
        settings: SETTINGS,
      });
      for (const node of nodes) {
        expect(Number.isFinite(node.x)).toBe(true);
        expect(Number.isFinite(node.y)).toBe(true);
        expect(Number.isFinite(node.z)).toBe(true);
      }
    }
  });
});

describe("placeOwnedByKind", () => {
  it("places every member inside the bubble", () => {
    const groups = [
      [mkNode("a1"), mkNode("a2"), mkNode("a3"), mkNode("a4")],
      [mkNode("b1"), mkNode("b2")],
    ];
    placeOwnedByKind({
      nodes: groups.flat(),
      groups,
      centre: ORIGIN,
      maxRadius: 100,
      settings: SETTINGS,
    });
    for (const member of groups.flat()) {
      // Kind-band inner/outer = 0.12/0.75 of maxRadius. All members
      // land inside 0.75 * 100 = 75.
      expect(radialDist(member, ORIGIN)).toBeLessThanOrEqual(75 + 1e-6);
    }
  });

  it("skips zero-size groups silently", () => {
    const groups = [[mkNode("a")], []];
    expect(() =>
      placeOwnedByKind({
        nodes: groups.flat(),
        groups,
        centre: ORIGIN,
        maxRadius: 100,
        settings: SETTINGS,
      }),
    ).not.toThrow();
  });
});

describe("placeOwnedCloud", () => {
  it("no-op for empty input", () => {
    expect(() =>
      placeOwnedCloud({
        nodes: [],
        centre: ORIGIN,
        maxRadius: 100,
        settings: SETTINGS,
      }),
    ).not.toThrow();
  });

  it("n=1 writes the centre", () => {
    const n = mkNode("a");
    placeOwnedCloud({
      nodes: [n],
      centre: { x: 5, y: 5, z: 5 },
      maxRadius: 100,
      settings: SETTINGS,
    });
    expect(n.x).toBe(5);
    expect(n.y).toBe(5);
    expect(n.z).toBe(5);
  });

  it("single-kind → placeOwnedBall path", () => {
    const nodes = [mkNode("a"), mkNode("b"), mkNode("c")]; // all "module"
    placeOwnedCloud({
      nodes,
      centre: ORIGIN,
      maxRadius: 100,
      settings: SETTINGS,
    });
    // Ball branch: small-n clamp at 0.85 * 100.
    for (const n of nodes) {
      expect(radialDist(n, ORIGIN)).toBeLessThanOrEqual(100 * 0.85 + 1e-6);
    }
  });

  it("multi-kind → placeOwnedByKind path", () => {
    const nodes = [
      mkNode("m1", "module"),
      mkNode("m2", "module"),
      mkNode("f1", "function"),
      mkNode("f2", "function"),
    ];
    placeOwnedCloud({
      nodes,
      centre: ORIGIN,
      maxRadius: 100,
      settings: SETTINGS,
    });
    // Kind-band outer = 0.75 * 100.
    for (const n of nodes) {
      expect(radialDist(n, ORIGIN)).toBeLessThanOrEqual(75 + 1e-6);
    }
  });

  it("relaxes connected clusters when edges are supplied", () => {
    const nodes = [mkNode("a"), mkNode("b"), mkNode("c"), mkNode("d")];
    const edges = new Map<string, readonly string[]>([
      ["a", ["b"]],
      ["b", ["a", "c"]],
      ["c", ["b", "d"]],
      ["d", ["c"]],
    ]);
    placeOwnedCloud({
      nodes,
      centre: ORIGIN,
      maxRadius: 100,
      settings: SETTINGS,
      edges,
    });
    // All nodes still within the bubble after relaxation.
    for (const n of nodes) {
      expect(radialDist(n, ORIGIN)).toBeLessThanOrEqual(100 + 1e-6);
      expect(Number.isFinite(n.x)).toBe(true);
      expect(Number.isFinite(n.y)).toBe(true);
      expect(Number.isFinite(n.z)).toBe(true);
    }
  });
});
