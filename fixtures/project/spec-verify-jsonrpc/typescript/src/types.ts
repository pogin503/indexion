export interface JsonRpcRequest {
  jsonrpc: string;
  method: string;
  params?: unknown;
  id?: string | number | null;
}

export interface JsonRpcResponse {
  jsonrpc: string;
  result?: unknown;
  error?: JsonRpcError;
  id: string | number | null;
}

export interface JsonRpcError {
  code: number;
  message: string;
}
