///|
/// JSON-RPC 2.0 Request object.
pub(all) struct JsonRpcRequest {
  jsonrpc : String
  method : String
  params : Json?
  id : Json?
}

///|
/// JSON-RPC 2.0 Response object.
pub(all) struct JsonRpcResponse {
  jsonrpc : String
  result : Json?
  error : JsonRpcError?
  id : Json?
}

///|
/// JSON-RPC 2.0 Error object.
pub(all) struct JsonRpcError {
  code : Int
  message : String
}
