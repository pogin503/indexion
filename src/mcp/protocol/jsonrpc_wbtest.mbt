///|
test "parse valid request" {
  let req = JsonRpcRequest::from_json_string(
    "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}",
  )
  guard req is Some(r) else { fail("expected Some") }
  inspect(r.meth, content="tools/list")
  inspect(r.jsonrpc, content="2.0")
  inspect(r.is_notification(), content="false")
}

///|
test "parse notification (no id)" {
  let req = JsonRpcRequest::from_json_string(
    "{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}",
  )
  guard req is Some(r) else { fail("expected Some") }
  inspect(r.is_notification(), content="true")
}

///|
test "parse invalid json returns None" {
  let req = JsonRpcRequest::from_json_string("not json")
  inspect(req is None, content="true")
}

///|
test "parse missing method returns None" {
  let req = JsonRpcRequest::from_json_string("{\"jsonrpc\":\"2.0\",\"id\":1}")
  inspect(req is None, content="true")
}

///|
test "response_ok builds valid JSON-RPC response" {
  let id : Json = @json.parse("1")
  let result : Json = @json.parse("true")
  let resp = response_ok(Some(id), result)
  inspect(resp, content="{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":true}")
}

///|
test "response_error builds valid JSON-RPC error" {
  let id : Json = @json.parse("2")
  let resp = response_error(Some(id), -32601, "Method not found")
  inspect(
    resp,
    content="{\"jsonrpc\":\"2.0\",\"id\":2,\"error\":{\"code\":-32601,\"message\":\"Method not found\"}}",
  )
}
