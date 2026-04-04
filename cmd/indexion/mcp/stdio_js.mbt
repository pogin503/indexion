///|
/// Stub for JS target where stdio transport is unavailable.
async fn run_stdio_transport(_server : @mcp_server.McpServer) -> Unit {
  println("Error: stdio transport is only available on native target")
}
