// Tests for the real typescript.kgf spec — regressions for multiline imports
// and ModuleDoc greediness. Loads kgfs/programming/typescript.kgf from disk so
// spec changes will surface here intentionally.

///|
fn load_typescript_kgf() -> String {
  @fs.read_file_to_string("kgfs/programming/typescript.kgf") catch {
    _ => panic()
  }
}

///|
fn run_typescript_pipeline(source : String) -> @graph.CodeGraph {
  run_full_pipeline(load_typescript_kgf(), source, "test.ts")
}

///|
fn ts_declares_edges(
  graph : @graph.CodeGraph,
) -> Array[(String, String, String)] {
  let result : Array[(String, String, String)] = []
  for edge in graph.get_edges() {
    if edge.kind is @graph.Declares {
      let name = edge.attrs.get("name").unwrap_or("")
      let kind = edge.attrs.get("kind").unwrap_or("")
      let doc = edge.attrs.get("doc").unwrap_or("")
      result.push((name, kind, doc))
    }
  }
  result
}

///|
fn ts_module_deps(graph : @graph.CodeGraph) -> Array[String] {
  let result : Array[String] = []
  for edge in graph.get_edges() {
    if edge.kind is @graph.ModuleDependsOn {
      result.push(edge.attrs.get("via").unwrap_or(""))
    }
  }
  result
}

///|
/// Find the declares edge for `name`. TypeScript emits two edges per exported
/// decl (one from the inner *Decl rule without doc, one from ExportDecl with
/// doc) — prefer the one carrying a non-empty doc so assertions see the JSDoc.
fn ts_find_edge(
  edges : Array[(String, String, String)],
  name : String,
) -> (String, String, String)? {
  let matches = edges.iter().filter(fn(e) { e.0 == name }).collect()
  match matches.iter().find_first(fn(e) { e.2 != "" }) {
    Some(e) => Some(e)
    None => matches.iter().find_first(fn(_) { true })
  }
}

// ---------------------------------------------------------------------------
// Multiline `import { ... }` — `ImportNamed` must accept newlines inside braces
// ---------------------------------------------------------------------------

///|
test "typescript kgf: multiline import type { ... } parses into dependency edge" {
  let source =
    #|import type {
    #|  FooType,
    #|  BarType,
    #|  BazType,
    #|} from "./types";
    #|
    #|export const x = 1;
  let graph = run_typescript_pipeline(source)
  let deps = ts_module_deps(graph)
  assert_true(deps.iter().any(fn(v) { v == "./types" }))
  let edges = ts_declares_edges(graph)
  assert_true(ts_find_edge(edges, "x") is Some(_))
}

///|
test "typescript kgf: multiline named import with trailing comma" {
  let source =
    #|import {
    #|  one,
    #|  two,
    #|} from "./mod";
  let graph = run_typescript_pipeline(source)
  let deps = ts_module_deps(graph)
  assert_true(deps.iter().any(fn(v) { v == "./mod" }))
}

///|
test "typescript kgf: multiline default+named import" {
  let source =
    #|import Default, {
    #|  one,
    #|  two
    #|} from "./mod";
  let graph = run_typescript_pipeline(source)
  let deps = ts_module_deps(graph)
  assert_true(deps.iter().any(fn(v) { v == "./mod" }))
}

///|
test "typescript kgf: multiline re-export followed by decl parses" {
  // Re-exports from "./mod" don't emit module_depends_on edges today (semantics
  // only wire ExportDecl to declares), but the grammar must still accept the
  // multiline `{ … }` block — verify by checking the following export parses.
  let source =
    #|export {
    #|  foo,
    #|  bar,
    #|} from "./mod";
    #|
    #|export const x = 1;
  let graph = run_typescript_pipeline(source)
  let edges = ts_declares_edges(graph)
  assert_true(ts_find_edge(edges, "x") is Some(_))
}

// ---------------------------------------------------------------------------
// ModuleDoc greediness — a leading JSDoc immediately before `export` must stay
// attached to the declaration, not be consumed as ModuleDoc.
// ---------------------------------------------------------------------------

///|
test "typescript kgf: leading JSDoc before export is declaration doc, not ModuleDoc" {
  let source =
    #|/**
    #| * First export doc belongs to foo.
    #| */
    #|export function foo() {}
  let graph = run_typescript_pipeline(source)
  let edges = ts_declares_edges(graph)
  let foo = ts_find_edge(edges, "foo")
  assert_true(foo is Some(_))
  assert_true(foo.unwrap().2.contains("First export doc belongs to foo"))
  let notes = graph.get_notes("module_doc", "test.ts")
  assert_eq(notes.length(), 0)
}

///|
test "typescript kgf: two exports each keep their own JSDoc" {
  let source =
    #|/**
    #| * Doc for foo.
    #| */
    #|export function foo() {}
    #|
    #|/**
    #| * Doc for bar.
    #| */
    #|export function bar() {}
  let graph = run_typescript_pipeline(source)
  let edges = ts_declares_edges(graph)
  let foo = ts_find_edge(edges, "foo")
  let bar = ts_find_edge(edges, "bar")
  assert_true(foo is Some(_))
  assert_true(bar is Some(_))
  assert_true(foo.unwrap().2.contains("Doc for foo"))
  assert_true(bar.unwrap().2.contains("Doc for bar"))
}

///|
test "typescript kgf: blank line between JSDoc and export still keeps doc on export" {
  // Even with a blank line, the first JSDoc should stay with foo because a
  // DeclKeyword follows after the NLs (negative lookahead fails → backtrack).
  let source =
    #|/**
    #| * Doc for foo.
    #| */
    #|
    #|export function foo() {}
  let graph = run_typescript_pipeline(source)
  let edges = ts_declares_edges(graph)
  let foo = ts_find_edge(edges, "foo")
  assert_true(foo is Some(_))
  assert_true(foo.unwrap().2.contains("Doc for foo"))
  let notes = graph.get_notes("module_doc", "test.ts")
  assert_eq(notes.length(), 0)
}

///|
test "typescript kgf: standalone JSDoc not followed by declaration is ModuleDoc" {
  let source =
    #|/**
    #| * Module-level overview.
    #| */
    #|
    #|
  let graph = run_typescript_pipeline(source)
  let notes = graph.get_notes("module_doc", "test.ts")
  assert_eq(notes.length(), 1)
  assert_true(notes[0].content.contains("Module-level overview"))
}
