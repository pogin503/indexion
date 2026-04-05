# JSON-RPC 2.0 Specification

JSON-RPC is a stateless, light-weight remote procedure call (RPC) protocol.
This specification defines the data structures and processing rules.

## Request Object

A rpc call is represented by sending a Request object to a Server.

```json
{
  "jsonrpc": "2.0",
  "method": "subtract",
  "params": [42, 23],
  "id": 1
}
```

The Request object contains the following members:

- **jsonrpc** - a String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
- **method** - a String containing the name of the method to be invoked.
- **params** - a Structured value that holds the parameter values to be used during the invocation of the method. This member MAY be omitted.
- **id** - an identifier established by the Client. If included, it MUST contain a String, Number, or NULL value.

### Named Parameters

```json
{
  "jsonrpc": "2.0",
  "method": "subtract",
  "params": {"subtrahend": 23, "minuend": 42},
  "id": 3
}
```

## Notification

A Notification is a Request object without an "id" member.

```json
{"jsonrpc": "2.0", "method": "update", "params": [1,2,3,4,5]}
```

```json
{"jsonrpc": "2.0", "method": "foobar"}
```

## Response Object

When a rpc call is made, the Server MUST reply with a Response.

```json
{
  "jsonrpc": "2.0",
  "result": 19,
  "id": 1
}
```

The Response object contains the following members:

- **jsonrpc** - MUST be exactly "2.0".
- **result** - this member is REQUIRED on success. This member MUST NOT exist if there was an error.
- **error** - this member is REQUIRED on error. This member MUST NOT exist if there was no error.
- **id** - this member is REQUIRED. It MUST be the same as the value of the id member in the Request Object.

## Error Object

When a rpc call encounters an error, the Response Object MUST contain the error member.

```json
{
  "jsonrpc": "2.0",
  "error": {"code": -32601, "message": "Method not found"},
  "id": "1"
}
```

The error object contains the following members:

- **code** - a Number that indicates the error type that occurred.
- **message** - a String providing a short description of the error.
- **data** - a Primitive or Structured value that contains additional information about the error. This may be omitted.

```json
{
  "jsonrpc": "2.0",
  "error": {"code": -32603, "message": "Internal error", "data": {"trace": "..."}},
  "id": null
}
```

## Batch

To send several Request objects at the same time, the Client MAY send an Array filled with Request objects.

```json
[
  {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
  {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]},
  {"jsonrpc": "2.0", "method": "subtract", "params": [42,23], "id": "2"},
  {"jsonrpc": "2.0", "method": "get_data", "id": "9"}
]
```
