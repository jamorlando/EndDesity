"""认证业务服务：登录、令牌刷新、改密、登出。"""
from __future__ import annotations

import jwt
from datetime import datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BusinessValidationError, UnauthorizedError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.modules.auth.models import PasswordHistory, User
from app.utils.serializers import fmt_dt, to_int


def serialize_user(user: User) -> dict[str, Any]:
    """用户对象 -> 前端所需字典 (is_root 输出 0/1 整数)。"""
    return {
        "id": to_int(user.id),
        "team_id": to_int(user.team_id) if user.team_id is not None else None,
        "username": user.username,
        "real_name": user.real_name,
        "email": user.email,
        "phone": user.phone,
        "avatar_url": user.avatar_url,
        "role": user.role,
        "status": user.status,
        "is_root": to_int(user.is_root),
        "wechat_userid": user.wechat_userid,
        "created_at": fmt_dt(user.created_at),
    }


async def authenticate(db: AsyncSession, username: str, password: str) -> dict[str, Any]:
    """校验账号密码并签发令牌。异常账号状态抛出 401/403 业务错误。"""
    result = await db.execute(select(User).where(User.username == username))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(password, user.hashed_password):
        raise UnauthorizedError("账号或密码不正确")

    if user.status != "ACTIVE":
        if user.status == "PENDING_REVIEW":
            raise UnauthorizedError("账号待管理员审核，请稍后再试")
        if user.status == "DISABLED":
            raise UnauthorizedError("账号已被禁用，请联系管理员")
        if user.status == "LOCKED":
            raise UnauthorizedError("账号已锁定，请稍后重试")
        if user.status == "PASSWORD_EXPIRED":
            raise UnauthorizedError("密码已过期，请联系管理员重置")

    access_token = create_access_token(user.id, user.role, user.team_id)
    refresh_token = create_refresh_token(user.id)
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": serialize_user(user),
    }


async def refresh_access_token(db: AsyncSession, refresh_token: str) -> dict[str, Any]:
    """刷新访问令牌。"""
    try:
        payload = decode_token(refresh_token)
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError, jwt.PyJWTError) as exc:
        raise UnauthorizedError("刷新令牌无效或已过期") from exc

    if payload.get("type") != "refresh":
        raise UnauthorizedError("令牌类型错误")

    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedError()

    result = await db.execute(select(User).where(User.id == int(user_id)))
    user = result.scalar_one_or_none()
    if user is None:
        raise UnauthorizedError("用户不存在")

    return {
        "access_token": create_access_token(user.id, user.role, user.team_id),
        "refresh_token": create_refresh_token(user.id),
        "token_type": "bearer",
        "user": serialize_user(user),
    }


async def change_password(
    db: AsyncSession, user: User, old_password: str, new_password: str
) -> None:
    """修改当前用户密码，记录历史哈希防止近 3 次重复。"""
    if not verify_password(old_password, user.hashed_password):
        raise BusinessValidationError("原密码不正确")

    if verify_password(new_password, user.hashed_password):
        raise BusinessValidationError("新密码不能与当前密码相同")

    # 近 3 次历史重复校验
    result = await db.execute(
        select(PasswordHistory)
        .where(PasswordHistory.user_id == user.id)
        .order_by(PasswordHistory.created_at.desc())
        .limit(3)
    )
    for hist in result.scalars().all():
        if verify_password(new_password, hist.hashed_password):
            raise BusinessValidationError("新密码不能与近期使用的密码重复")

    now = datetime.now()
    new_hash = hash_password(new_password)
    db.add(PasswordHistory(user_id=user.id, hashed_password=user.hashed_password, created_at=now))
    user.hashed_password = new_hash
    user.password_changed_at = now
    user.updated_at = now
    await db.commit()