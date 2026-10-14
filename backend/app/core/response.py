"""统一 JSON 响应体包装工具。"""
from __future__ import annotations

import time
from typing import Any

from fastapi.responses import JSONResponse


def ok(data: Any = None, message: str = "success", code: int = 200) -> JSONResponse:
    """构造标准成功响应 {code, message, data, timestamp}。"""
    return JSONResponse(
        status_code=200,
        content={
            "code": code,
            "message": message,
            "data": data,
            "timestamp": int(time.time()),
        },
    )


def fail(status_code: int, message: str, code: int | None = None) -> JSONResponse:
    """构造标准失败响应 (兼容前端读取 detail/message 双重字段)。"""
    return JSONResponse(
        status_code=status_code,
        content={
            "code": code if code is not None else status_code,
            "message": message,
            "detail": message,
            "data": None,
            "timestamp": int(time.time()),
        },
    )