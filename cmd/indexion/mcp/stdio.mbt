///|
/// Run MCP server over stdio transport (native only).
async fn run_stdio_transport(server : @mcp_server.McpServer) -> Unit {
  @transport.run_stdio(server, @async_stdio.stdin)
}
