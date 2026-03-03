/**
 * @file Generate graph.json from SQL DDL schema using sql-ddl.kgf
 * Run: bun run src/kgf/__fixtures__/examples/sql-ddl/generate-graph.ts
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { parseKGF } from "../../../spec";
import { buildLexer } from "../../../lexer";
import { buildPEG, runParse, type ExecCtx } from "../../../peg";
import { createGraph, toJSON } from "../../../graph";
import { nodeFileResolver } from "../../../env-node";

const kgfPath = join("src", "kgf", "__fixtures__", "specs", "sql-ddl.kgf");
const schemaPath = join("src", "kgf", "__fixtures__", "examples", "sql-ddl", "schema.sql");
const outputPath = join("src", "kgf", "__fixtures__", "examples", "sql-ddl", "graph.json");

const kgfText = readFileSync(kgfPath, "utf8");
const schema = readFileSync(schemaPath, "utf8");

const spec = parseKGF(kgfText);
const lexer = buildLexer(spec.tokens, spec.preprocess, spec.preprocessFst);
const peg = buildPEG(spec);

const tokens = lexer(schema);
const graph = createGraph();

const ctx: ExecCtx = {
  spec,
  graph,
  file: "schema.sql",
  root: dirname(schemaPath),
  fileResolver: nodeFileResolver,
  scopes: [{ value: {}, type: {} }],
  symSeq: 0,
  callSeq: 0,
  callStack: [],
  eventsTmp: [],
};

runParse(peg, spec, "Doc", tokens, ctx);

const json = toJSON(graph);

writeFileSync(outputPath, JSON.stringify(json, null, 2));
console.log(`Generated ${outputPath}`);
console.log(`Modules: ${Object.keys(json.modules).length}`);
console.log(`Symbols: ${Object.keys(json.symbols).length}`);
console.log(`Edges: ${json.edges.length}`);
