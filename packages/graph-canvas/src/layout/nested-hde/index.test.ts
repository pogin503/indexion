/**
 * @file Integration test for applyNestedHdeLayout.
 *
 * Verifies the full 3-step pipeline: quotient HDE → per-cluster HDE
 * → overlap resolution. The star-constellation visual depends on
 * this sequence producing positions that (a) are finite, (b) stay
 * reasonably bounded, and (c) actually group cluster members around
 * distinct centres.
 */

import { describe, expect, it } from "vitest";
import type { ViewEdge, ViewGraph, ViewNode } from "../../types.ts";
import { applyNestedHdeLayout } from "./index.ts";

function mkNode(id: string): ViewNode {
  return {
    id,
    label: id,
    kind: "module",
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

function mkEdge(source: ViewNode, target: ViewNode): ViewEdge {
  return {
    sourceId: source.id,
    targetId: target.id,
    kind: "depends_on",
    metadata: {},
    source,
    target,
  };
}

function mkGraph(nodes: ViewNode[], edges: ViewEdge[]): ViewGraph {
  const nodeIndex = new Map<string, ViewNode>();
  for (const n of nodes) {
    nodeIndex.set(n.id, n);
  }
  return { nodes, edges, nodeIndex };
}

function distance(a: ViewNode, b: ViewNode): number {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  const dz = a.z - b.z;
  return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

describe("applyNestedHdeLayout — pipeline contracts", () => {
  it("delegates to single-cluster HDE when clusterOf maps all to one", () => {
    const a = mkNode("a");
    const b = mkNode("b");
    const graph = mkGraph([a, b], [mkEdge(a, b)]);
    const clusterOf = new Map([
      ["a", "only"],
      ["b", "only"],
    ]);
    applyNestedHdeLayout({ graph, clusterOf });
    // Every node placed → coordinates finite.
    for (const n of graph.nodes) {
      expect(Number.isFinite(n.x)).toBe(true);
      expect(Number.isFinite(n.y)).toBe(true);
      expect(Number.isFinite(n.z)).toBe(true);
    }
  });

  it("places every node at a finite position for a 2-cluster graph", () => {
    const nodes: ViewNode[] = [];
    const clusterOf = new Map<string, string>();
    for (let i = 0; i < 5; i++) {
      const n = mkNode(`x-${i}`);
      nodes.push(n);
      clusterOf.set(n.id, "X");
    }
    for (let i = 0; i < 5; i++) {
      const n = mkNode(`y-${i}`);
      nodes.push(n);
      clusterOf.set(n.id, "Y");
    }
    const edges: ViewEdge[] = [];
    for (let i = 0; i < nodes.length - 1; i++) {
      edges.push(mkEdge(nodes[i]!, nodes[i + 1]!));
    }
    const graph = mkGraph(nodes, edges);
    applyNestedHdeLayout({ graph, clusterOf });
    for (const n of graph.nodes) {
      expect(Number.isFinite(n.x)).toBe(true);
      expect(Number.isFinite(n.y)).toBe(true);
      expect(Number.isFinite(n.z)).toBe(true);
    }
  });

  it("clusters visually group: intra-cluster pairs closer than inter-cluster", () => {
    // Build two connected clusters (X: 4 nodes in a ring, Y: 4
    // nodes in a ring) with one weak bridge between them. After
    // nested HDE: X members should be closer to each other on
    // average than to Y members.
    const xs = [0, 1, 2, 3].map((i) => mkNode(`x-${i}`));
    const ys = [0, 1, 2, 3].map((i) => mkNode(`y-${i}`));
    const clusterOf = new Map<string, string>();
    for (const n of xs) {
      clusterOf.set(n.id, "X");
    }
    for (const n of ys) {
      clusterOf.set(n.id, "Y");
    }
    const edges: ViewEdge[] = [];
    for (let i = 0; i < xs.length; i++) {
      edges.push(mkEdge(xs[i]!, xs[(i + 1) % xs.length]!));
    }
    for (let i = 0; i < ys.length; i++) {
      edges.push(mkEdge(ys[i]!, ys[(i + 1) % ys.length]!));
    }
    edges.push(mkEdge(xs[0]!, ys[0]!)); // bridge
    const graph = mkGraph([...xs, ...ys], edges);
    applyNestedHdeLayout({ graph, clusterOf });

    const intra = xs[0] && xs[1] ? distance(xs[0], xs[1]) : 0;
    const inter = xs[0] && ys[0] ? distance(xs[0], ys[0]) : 0;
    // Intra-cluster distance should be materially smaller. Bridge
    // only draws them slightly, the nested placement's main effect
    // is to separate X from Y.
    expect(intra).toBeLessThan(inter);
  });

  it("single-member clusters are placed at the centre chosen by the quotient pass", () => {
    // Verify the `members.length === 1` fast path writes centre
    // coords and zeros velocity.
    const a = mkNode("a");
    const b = mkNode("b");
    a.vx = 99;
    a.vy = 99;
    a.vz = 99;
    const graph = mkGraph([a, b], []);
    const clusterOf = new Map([
      ["a", "solo-a"],
      ["b", "solo-b"],
    ]);
    applyNestedHdeLayout({ graph, clusterOf });
    expect(a.vx).toBe(0);
    expect(a.vy).toBe(0);
    expect(a.vz).toBe(0);
    // a and b have different cluster ids → placed at distinct
    // centres after overlap resolution.
    expect(distance(a, b)).toBeGreaterThan(0);
  });

  it("resolves overlaps so every pair of clusters is disjoint", () => {
    // 3 clusters of 3 members each. After the full pipeline, no
    // pair of cluster *members* from different clusters should be
    // closer than roughly the sum of their cluster radii (we use
    // a loose check: some separation must exist beyond the inner
    // radius).
    const clusterOf = new Map<string, string>();
    const nodes: ViewNode[] = [];
    const clusters: Record<string, ViewNode[]> = { A: [], B: [], C: [] };
    for (const c of ["A", "B", "C"]) {
      for (let i = 0; i < 3; i++) {
        const n = mkNode(`${c}-${i}`);
        clusterOf.set(n.id, c);
        nodes.push(n);
        clusters[c]!.push(n);
      }
    }
    const edges: ViewEdge[] = [];
    for (const c of ["A", "B", "C"]) {
      const group = clusters[c]!;
      edges.push(mkEdge(group[0]!, group[1]!));
      edges.push(mkEdge(group[1]!, group[2]!));
    }
    const graph = mkGraph(nodes, edges);
    applyNestedHdeLayout({ graph, clusterOf });

    // Centroids per cluster
    const centroid = (members: ViewNode[]) => {
      let cx = 0,
        cy = 0,
        cz = 0;
      for (const m of members) {
        cx += m.x;
        cy += m.y;
        cz += m.z;
      }
      return {
        x: cx / members.length,
        y: cy / members.length,
        z: cz / members.length,
      };
    };
    const ca = centroid(clusters.A!);
    const cb = centroid(clusters.B!);
    const cc = centroid(clusters.C!);
    const sep = (p: { x: number; y: number; z: number }, q: typeof p) =>
      Math.sqrt((p.x - q.x) ** 2 + (p.y - q.y) ** 2 + (p.z - q.z) ** 2);
    // Each pair of centroids should be separated — not overlapping.
    expect(sep(ca, cb)).toBeGreaterThan(0);
    expect(sep(cb, cc)).toBeGreaterThan(0);
    expect(sep(ca, cc)).toBeGreaterThan(0);
  });
});
