///|
/// PEG represents a compiled PEG grammar with parsed rule ASTs.
pub struct PEG {
  tokens : @hashset.HashSet[String]
  ast : Map[String, Node]
  attrs : Map[String, Array[@types.AttrAction]]
  compiled_nodes : Array[CompiledNode]
  rule_node_ids : Map[String, Int]
}

///|
/// Creates a new empty PEG.
pub fn PEG::new() -> PEG {
  {
    tokens: @hashset.new(),
    ast: Map::new(),
    attrs: Map::new(),
    compiled_nodes: [],
    rule_node_ids: Map::new(),
  }
}

///|
/// Returns the token set.
pub fn PEG::get_tokens(self : PEG) -> @hashset.HashSet[String] {
  self.tokens
}

///|
/// Checks if a name is a token.
pub fn PEG::is_token(self : PEG, name : String) -> Bool {
  self.tokens.contains(name)
}

///|
/// Returns the AST map.
pub fn PEG::get_ast(self : PEG) -> Map[String, Node] {
  self.ast
}

///|
/// Gets the AST node for a specific rule.
pub fn PEG::get_rule(self : PEG, name : String) -> Node? {
  self.ast.get(name)
}

///|
/// Gets a compiled node by node id.
fn PEG::get_compiled_node(self : PEG, node_id : Int) -> CompiledNode? {
  self.compiled_nodes.get(node_id)
}

///|
/// Gets compiled root node id for a rule.
fn PEG::get_rule_node_id(self : PEG, name : String) -> Int? {
  self.rule_node_ids.get(name)
}

///|
/// Returns the attributes map.
pub fn PEG::get_attrs(self : PEG) -> Map[String, Array[@types.AttrAction]] {
  self.attrs
}

///|
/// Gets the attribute actions for a specific rule.
pub fn PEG::get_rule_attrs(
  self : PEG,
  name : String,
) -> Array[@types.AttrAction]? {
  self.attrs.get(name)
}

///|
/// Builds a PEG from a KGFSpec.
/// Parses all rule expressions into AST nodes and collects token names.
pub fn build_peg(spec : @types.KGFSpec) -> PEG raise {
  let tokens : @hashset.HashSet[String] = @hashset.new()
  // Collect non-skip tokens
  for token_def in spec.tokens {
    if not(token_def.skip) {
      tokens.add(token_def.name)
    }
  }
  let ast : Map[String, Node] = Map::new()
  let compiled_nodes : Array[CompiledNode] = []
  let rule_node_ids : Map[String, Int] = Map::new()
  // Parse all rule expressions
  for name, rule_def in spec.rules {
    let node = parse_expr(rule_def.expr)
    ast.set(name, node)
    let node_id = compile_node(node, compiled_nodes)
    rule_node_ids.set(name, node_id)
  }
  { tokens, ast, attrs: spec.attrs, compiled_nodes, rule_node_ids }
}

///|
/// Compiles an AST node into ID-based node table for faster evaluation.
fn compile_node(node : Node, out : Array[CompiledNode]) -> Int {
  let compiled = match node {
    Empty => CEmpty
    Sym(name) => CSym(name)
    Seq(nodes) => {
      let children : Array[Int] = []
      for child in nodes {
        children.push(compile_node(child, out))
      }
      CSeq(children)
    }
    Choice(nodes) => {
      let children : Array[Int] = []
      for child in nodes {
        children.push(compile_node(child, out))
      }
      CChoice(children)
    }
    Star(child) => CStar(compile_node(child, out))
    Plus(child) => CPlus(compile_node(child, out))
    Optional(child) => COptional(compile_node(child, out))
    Label(name, child) => CLabel(name, compile_node(child, out))
  }
  let id = out.length()
  out.push(compiled)
  id
}

///|
/// Collects rules that can affect semantic output.
/// This is used to suppress unnecessary parse events for pure grammar rules.
pub fn collect_active_rules(spec : @types.KGFSpec) -> @hashset.HashSet[String] {
  let active : @hashset.HashSet[String] = @hashset.new()
  for entry in spec.get_attrs() {
    active.add(entry.0)
  }
  match spec.get_semantics() {
    Some(semantics) =>
      for entry in semantics {
        active.add(entry.0)
      }
    None => ()
  }
  active
}
