/**
 * @file Generate graph.json from base64 PNG fixture using png-b64hex.kgf (base64→hex FST preprocess).
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { parseKGF } from "../../../spec";
import { buildLexer } from "../../../lexer";
import { buildPEG, runParse, type ExecCtx } from "../../../peg";
import { createGraph, toJSON } from "../../../graph";
import { nodeFileResolver } from "../../../env-node";

const kgfPath = join("src", "kgf", "__fixtures__", "specs", "png-b64hex.kgf");
const exampleDir = join("src", "kgf", "__fixtures__", "examples", "b64-png");
const inputPath = join(exampleDir, "logo.png.b64");
const graphPath = join(exampleDir, "graph.json");

const input = readFileSync(inputPath, "utf8");

const spec = parseKGF(readFileSync(kgfPath, "utf8"));
const lexer = buildLexer(spec.tokens, spec.preprocess, spec.preprocessFst);
const peg = buildPEG(spec);

const tokens = lexer(input);
const graph = createGraph();
const ctx: ExecCtx = {
  spec,
  graph,
  file: "logo.png.b64",
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
