"""自定义业务异常体系。

统一异常基类 AppException 继承 fastapi.HTTPException，细分三大子类；
全局异常处理器在 main.py 中注册，将业务异常转换为标准 JSON 结构。
"""
from __future__ import annotations

from fastapi import HTTPException, status


class AppException(HTTPException):
    """业务异常基类。message 同时透出给前端 detail/message 双字段。"""

    def __init__(self, status_code: int, message: str, code: int | None = None) -> None:
        super().__init__(status_code=status_code, detail=message)
        self.message = message
        self.code = code if code is not None else status_code


class ResourceNotFoundError(AppException):
    """资源不存在 (404)。"""

    def __init__(self, message: str = "请求的资源不存在") -> None:
        super().__init__(status.HTTP_404_NOT_FOUND, message)


class PermissionDeniedError(AppException):
    """权限不足 (403)。"""

    def __init__(self, message: str = "权限不足，禁止访问该资源") -> None:
        super().__init__(status.HTTP_403_FORBIDDEN, message)


class UnauthorizedError(AppException):
    """未登录或 Token 失效 (401)。"""

    def __init__(self, message: str = "登录凭证无效或已过期，请重新登录") -> None:
        super().__init__(status.HTTP_401_UNAUTHORIZED, message)


class BusinessValidationError(AppException):
    """客户端参数校验不通过 / 业务规则冲突 (400)。"""

    def __init__(self, message: str = "请求参数不合法") -> None:
        super().__init__(status.HTTP_400_BAD_REQUEST, message)