"""认证路由 (kebab-case REST)。"""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.response import ok
from app.modules.auth.models import User
from app.modules.auth.schemas import ChangePasswordRequest, LoginRequest, RefreshRequest
from app.modules.auth import service

router = APIRouter(prefix="/auth", tags=["认证"])


@router.post("/login")
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)):
    data = await service.authenticate(db, payload.username, payload.password)
    return ok(data, "登录成功")


@router.get("/me")
async def me(user: User = Depends(get_current_user)):
    return ok(service.serialize_user(user))


@router.post("/refresh")
async def refresh(payload: RefreshRequest, db: AsyncSession = Depends(get_db)):
    data = await service.refresh_access_token(db, payload.refresh_token)
    return ok(data, "令牌刷新成功")


@router.post("/change-password")
async def change_password(
    payload: ChangePasswordRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await service.change_password(db, user, payload.old_password, payload.new_password)
    return ok(None, "密码修改成功")


@router.post("/logout")
async def logout(user: User = Depends(get_current_user)):
    # JWT 无状态登出，前端负责清理本地凭证
    return ok(None, "已安全退出")