"""JSON-RPC 2.0 type definitions."""

from dataclasses import dataclass
from typing import Any, Optional


@dataclass
class JsonRpcError:
    """JSON-RPC 2.0 Error object."""

    code: int
    message: str


@dataclass
class JsonRpcRequest:
    """JSON-RPC 2.0 Request object."""

    jsonrpc: str
    method: str
    params: Optional[Any] = None
    id: Optional[Any] = None


@dataclass
class JsonRpcResponse:
    """JSON-RPC 2.0 Response object."""

    jsonrpc: str
    result: Optional[Any] = None
    error: Optional[JsonRpcError] = None
    id: Optional[Any] = None
