/**
 * @file Contract tests for sibling-slot allocation + permutation +
 * scaleSubtree.
 */

import { describe, expect, it } from "vitest";
import type { LayoutSettings } from "../../types.ts";
import {
  allocateSiblingsByIntrinsic,
  permutePlacementByOrder,
  scaleSubtree,
} from "./allocate.ts";
import { DEFAULT_RENDER_SETTINGS } from "../../renderer/settings.ts";
import { ORIGIN, type Vec3 } from "../geometry.ts";

const SETTINGS: LayoutSettings = DEFAULT_RENDER_SETTINGS.layout;

describe("allocateSiblingsByIntrinsic", () => {
  it("returns empty placement for n=0", () => {
    const p = allocateSiblingsByIntrinsic({
      parentRadius: 100,
      intrinsicRadii: [],
      settings: SETTINGS,
    });
    expect(p.positions).toEqual([]);
    expect(p.radii).toEqual([]);
  });

  it("n=1: origin position, radius = min(parent*0.85, intrinsic)", () => {
    const p = allocateSiblingsByIntrinsic({
      parentRadius: 100,
      intrinsicRadii: [30],
      settings: SETTINGS,
    });
    expect(p.positions).toEqual([ORIGIN]);
    expect(p.radii[0]).toBe(30);
  });

  it("n=1 with oversize intrinsic clamps to parent*0.85", () => {
    const p = allocateSiblingsByIntrinsic({
      parentRadius: 100,
      intrinsicRadii: [200],
      settings: SETTINGS,
    });
    expect(p.radii[0]).toBe(85);
  });

  it("n>=2: places siblings on a Fibonacci shell with no overlap", () => {
    // Pick intrinsic radii small enough that parent can host all
    // of them at intrinsic scale.
    const intrinsicRadii = [20, 20, 20, 20, 20];
    const p = allocateSiblingsByIntrinsic({
      parentRadius: 1000,
      intrinsicRadii,
      settings: SETTINGS,
    });
    expect(p.positions.length).toBe(5);
    expect(p.radii.length).toBe(5);
    // No pair of child spheres overlaps: centre-distance > ra + rb.
    for (let i = 0; i < p.positions.length; i++) {
      for (let j = i + 1; j < p.positions.length; j++) {
        const a = p.positions[i]!;
        const b = p.positions[j]!;
        const d = Math.sqrt(
          (a.x - b.x) ** 2 + (a.y - b.y) ** 2 + (a.z - b.z) ** 2,
        );
        expect(d).toBeGreaterThan(p.radii[i]! + p.radii[j]!);
      }
    }
  });

  it("scales down uniformly when the parent is too small", () => {
    // Intrinsic demands way more than the parent can fit. The
    // allocator should scale all radii by the same factor.
    const intrinsicRadii = [100, 100, 100, 100];
    const p = allocateSiblingsByIntrinsic({
      parentRadius: 50,
      intrinsicRadii,
      settings: SETTINGS,
    });
    // All radii should be < 100 and equal to each other.
    for (const r of p.radii) {
      expect(r).toBeLessThan(100);
    }
    const first = p.radii[0]!;
    for (const r of p.radii) {
      expect(r).toBeCloseTo(first, 6);
    }
  });
});

describe("permutePlacementByOrder", () => {
  it("remaps radii when refine reorders the paths", () => {
    const placement = {
      positions: [
        { x: 0, y: 0, z: 1 },
        { x: 0, y: 0, z: -1 },
      ],
      radii: [10, 20],
    };
    // Snapshot before the refinement.
    const orderedBefore = ["a", "b"];
    const ordered = [...orderedBefore];
    // refine that swaps the two entries in place.
    const refine = ({ ordered: o }: { ordered: string[] }) => {
      const t = o[0]!;
      o[0] = o[1]!;
      o[1] = t;
    };
    const result = permutePlacementByOrder({
      placement,
      orderedBefore,
      ordered,
      refine,
    });
    // After refine, ordered = ["b", "a"]. radii should track:
    // slot 0 now holds "b" whose old radius was 20; slot 1 holds
    // "a" whose old radius was 10.
    expect(ordered).toEqual(["b", "a"]);
    expect(result.radii).toEqual([20, 10]);
    // Positions are untouched (same objects).
    expect(result.positions).toBe(placement.positions);
  });

  it("passes the placement's positions through to refine untouched", () => {
    let seenPositions: readonly Vec3[] | null = null;
    const placement = {
      positions: [
        { x: 1, y: 2, z: 3 },
        { x: 4, y: 5, z: 6 },
      ],
      radii: [1, 2],
    };
    permutePlacementByOrder({
      placement,
      orderedBefore: ["a", "b"],
      ordered: ["a", "b"],
      refine: ({ positions }) => {
        seenPositions = positions;
      },
    });
    expect(seenPositions).toBe(placement.positions);
  });
});

describe("scaleSubtree", () => {
  function mkChildrenMap(
    edges: readonly [string, readonly string[]][],
  ): ReadonlyMap<string, readonly string[]> {
    return new Map(edges);
  }

  it("scales the path itself", () => {
    const intrinsic = new Map([["a", 100]]);
    scaleSubtree({
      path: "a",
      scale: 0.5,
      childrenOf: mkChildrenMap([]),
      intrinsic,
    });
    expect(intrinsic.get("a")).toBe(50);
  });

  it("recursively scales every descendant", () => {
    const intrinsic = new Map([
      ["a", 100],
      ["a/b", 50],
      ["a/b/c", 20],
      ["a/d", 30],
    ]);
    const childrenOf = mkChildrenMap([
      ["a", ["a/b", "a/d"]],
      ["a/b", ["a/b/c"]],
    ]);
    scaleSubtree({ path: "a", scale: 0.5, childrenOf, intrinsic });
    expect(intrinsic.get("a")).toBe(50);
    expect(intrinsic.get("a/b")).toBe(25);
    expect(intrinsic.get("a/b/c")).toBe(10);
    expect(intrinsic.get("a/d")).toBe(15);
  });

  it("silently skips paths missing from the intrinsic map", () => {
    const intrinsic = new Map([["a", 100]]);
    const childrenOf = mkChildrenMap([["a", ["missing"]]]);
    expect(() =>
      scaleSubtree({ path: "a", scale: 0.5, childrenOf, intrinsic }),
    ).not.toThrow();
    expect(intrinsic.get("a")).toBe(50);
    expect(intrinsic.has("missing")).toBe(false);
  });

  it("is a no-op at a leaf (no children, path not in intrinsic)", () => {
    const intrinsic = new Map<string, number>();
    scaleSubtree({
      path: "nowhere",
      scale: 0.5,
      childrenOf: mkChildrenMap([]),
      intrinsic,
    });
    expect(intrinsic.size).toBe(0);
  });
});
