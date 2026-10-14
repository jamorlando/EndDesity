"""项目路由。"""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.exceptions import PermissionDeniedError
from app.core.response import ok
from app.modules.auth.models import User
from app.modules.projects import service
from app.modules.projects.schemas import ProjectCreateRequest, ProjectUpdateRequest

router = APIRouter(prefix="/projects", tags=["项目"])


def _require_leader(user: User) -> None:
    if user.role not in ("SUPER_ADMIN", "TEAM_LEADER") and user.is_root != 1:
        raise PermissionDeniedError("仅团队主管或管理员可管理项目")


@router.get("")
async def list_projects(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return ok(await service.list_projects(db, user))


@router.get("/{project_id}")
async def project_detail(
    project_id: int,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return ok(await service.get_project_detail(db, project_id, user))


@router.post("")
async def create_project(
    payload: ProjectCreateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    _require_leader(user)
    data = await service.create_project(db, user, payload)
    return ok(data, "项目创建成功")


@router.put("/{project_id}")
async def update_project(
    project_id: int,
    payload: ProjectUpdateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    _require_leader(user)
    await service.update_project(db, user, project_id, payload)
    return ok(None, "项目更新成功")