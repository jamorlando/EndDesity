"""团队路由。"""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.exceptions import PermissionDeniedError
from app.core.response import ok
from app.modules.auth.models import User
from app.modules.teams import service
from app.modules.teams.schemas import TeamCreateRequest, TeamUpdateRequest

router = APIRouter(prefix="/teams", tags=["团队"])


def _require_root(user: User) -> None:
    if user.role != "SUPER_ADMIN" and user.is_root != 1:
        raise PermissionDeniedError("仅超级管理员可管理团队架构")


@router.get("")
async def list_teams(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return ok(await service.list_teams(db))


@router.get("/{team_id}")
async def team_detail(team_id: int, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return ok(await service.get_team_detail(db, team_id))


@router.post("")
async def create_team(
    payload: TeamCreateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    _require_root(user)
    data = await service.create_team(db, payload)
    return ok(data, "团队创建成功")


@router.put("/{team_id}")
async def update_team(
    team_id: int,
    payload: TeamUpdateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    _require_root(user)
    await service.update_team(db, team_id, payload)
    return ok(None, "团队更新成功")