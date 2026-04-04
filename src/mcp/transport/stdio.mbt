///|
/// # MCP stdio transport
///
/// Reads JSON-RPC messages line-by-line from stdin, dispatches them
/// to the MCP server, and writes responses to stdout.
///
/// Per MCP spec, stdio transport uses newline-delimited JSON.
/// Each message is a single line of JSON followed by a newline.

///|
/// Run the MCP server over stdio transport.
/// Reads lines from stdin until EOF, dispatches each to the server,
/// and writes responses to stdout.
pub async fn run_stdio(server : @server.McpServer, input : &@io.Reader) -> Unit {
  while true {
    let line = match input.read_until("\n") {
      Some(s) => s
      None => break
    }
    // Skip empty lines
    if line.length() == 0 {
      continue
    }
    match server.handle_message(line) {
      Some(response) => println(response)
      // Stdout is line-buffered; println adds newline
      None =>
        // Notification — no response needed
        ()
    }
  }
}
