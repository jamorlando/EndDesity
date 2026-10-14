"""FastAPI 依赖注入：数据库会话 + 当前登录用户。"""
from __future__ import annotations

from typing import AsyncGenerator, Optional

import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.core.exceptions import UnauthorizedError
from app.core.security import decode_token
from app.modules.auth.models import User

_bearer_scheme = HTTPBearer(auto_error=False)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """提供一个请求级异步会话，请求结束后自动关闭。"""
    async with AsyncSessionLocal() as session:
        yield session


def _resolve_token(credentials: Optional[HTTPAuthorizationCredentials]) -> str:
    if credentials is None or not credentials.credentials:
        raise UnauthorizedError()
    return credentials.credentials


async def get_current_user(
    db: AsyncSession = Depends(get_db),
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
) -> User:
    """解析 Authorization: Bearer 令牌并加载当前用户。

    - 令牌签名/过期无效 -> 401
    - 账号非 ACTIVE -> 401
    """
    token = _resolve_token(credentials)
    try:
        payload = decode_token(token)
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError, jwt.PyJWTError) as exc:
        raise UnauthorizedError() from exc

    if payload.get("type") != "access":
        raise UnauthorizedError()

    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedError()

    result = await db.execute(select(User).where(User.id == int(user_id)))
    user = result.scalar_one_or_none()
    if user is None:
        raise UnauthorizedError("用户不存在或已被删除")

    if user.status != "ACTIVE":
        raise UnauthorizedError("账号状态异常，请联系管理员")

    return user