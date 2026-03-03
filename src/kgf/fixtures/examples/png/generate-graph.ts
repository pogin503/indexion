/**
 * @file Generate graph.json from PNG fixture using png-hex.kgf.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { parseKGF } from "../../../spec";
import { buildLexer } from "../../../lexer";
import { buildPEG, runParse, type ExecCtx } from "../../../peg";
import { createGraph, toJSON } from "../../../graph";
import { nodeFileResolver } from "../../../env-node";

function toHex(buf: Uint8Array): string {
  return Buffer.from(buf).toString("hex").toUpperCase();
}

const kgfPath = join("src", "kgf", "__fixtures__", "specs", "png-hex.kgf");
const exampleDir = join("src", "kgf", "__fixtures__", "examples", "png");
const imagePath = join(exampleDir, "logo.png");
const hexPath = join(exampleDir, "logo.png.hex");
const graphPath = join(exampleDir, "graph.json");

const image = readFileSync(imagePath);
const hex = toHex(image);
writeFileSync(hexPath, hex, "utf8");

const spec = parseKGF(readFileSync(kgfPath, "utf8"));
const lexer = buildLexer(spec.tokens, spec.preprocess, spec.preprocessFst);
const peg = buildPEG(spec);

const tokens = lexer(hex);
const graph = createGraph();
const ctx: ExecCtx = {
  spec,
  graph,
  file: "logo.png",
  root: "/project",
  fileResolver: nodeFileResolver,
  scopes: [{ value: {}, type: {} }],
  symSeq: 0,
  callSeq: 0,
  callStack: [],
  eventsTmp: [],
};

runParse(peg, spec, "Doc", tokens, ctx);
writeFileSync(graphPath, JSON.stringify(toJSON(graph), null, 2), "utf8");
