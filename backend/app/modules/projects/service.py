"""企业项目业务服务 (跨组项目 + 项目成员 + 行级隔离)。"""
from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BusinessValidationError, PermissionDeniedError, ResourceNotFoundError
from app.modules.auth.models import User
from app.modules.projects.models import Project, ProjectMember
from app.modules.teams.models import Team
from app.utils.serializers import fmt_date, fmt_dt, to_int


async def _user_map(db: AsyncSession, user_ids: set[int]) -> dict[int, User]:
    if not user_ids:
        return {}
    result = await db.execute(select(User).where(User.id.in_(user_ids)))
    return {u.id: u for u in result.scalars().all()}


async def _team_map(db: AsyncSession, team_ids: set[int]) -> dict[int, Team]:
    if not team_ids:
        return {}
    result = await db.execute(select(Team).where(Team.id.in_(team_ids)))
    return {t.id: t for t in result.scalars().all()}


async def list_projects(db: AsyncSession, current_user: User) -> list[dict[str, Any]]:
    """项目卡片列表。root 看全部，普通用户看本团队项目。"""
    stmt = select(Project).order_by(Project.id)
    if current_user.role != "SUPER_ADMIN" and current_user.is_root != 1:
        stmt = stmt.where(Project.team_id == current_user.team_id)
    projects = (await db.execute(stmt)).scalars().all()

    member_counts = dict(
        (await db.execute(
            select(ProjectMember.project_id, func.count(ProjectMember.id)).group_by(ProjectMember.project_id)
        )).all()
    )
    team_ids = {p.team_id for p in projects}
    manager_ids = {p.manager_id for p in projects if p.manager_id}
    teams = await _team_map(db, team_ids)
    users = await _user_map(db, manager_ids)

    return [
        {
            "id": to_int(p.id),
            "code": p.code,
            "name": p.name,
            "team_id": to_int(p.team_id),
            "team_name": teams[p.team_id].name if p.team_id in teams else None,
            "manager_id": to_int(p.manager_id) if p.manager_id else None,
            "manager_name": users[p.manager_id].real_name if p.manager_id in users else None,
            "start_date": fmt_date(p.start_date),
            "end_date": fmt_date(p.end_date),
            "status": p.status,
            "description": p.description,
            "member_count": member_counts.get(p.id, 0),
            "created_at": fmt_dt(p.created_at),
        }
        for p in projects
    ]


async def get_project_detail(db: AsyncSession, project_id: int, current_user: User) -> dict[str, Any]:
    project = await db.get(Project, project_id)
    if project is None:
        raise ResourceNotFoundError("项目不存在")

    if current_user.role != "SUPER_ADMIN" and current_user.is_root != 1:
        if project.team_id != current_user.team_id:
            raise ResourceNotFoundError("项目不存在")

    members = (await db.execute(
        select(ProjectMember).where(ProjectMember.project_id == project_id)
    )).scalars().all()

    member_user_ids = {m.user_id for m in members}
    user_map = await _user_map(db, member_user_ids)
    team_map = await _team_map(db, {project.team_id})

    serialized_members = []
    for m in members:
        u = user_map.get(m.user_id)
        serialized_members.append({
            "user_id": to_int(m.user_id),
            "real_name": u.real_name if u else None,
            "username": u.username if u else None,
            "email": u.email if u else None,
            "phone": u.phone if u else None,
            "project_role": m.project_role,
        })

    manager = user_map.get(project.manager_id) if project.manager_id else None

    return {
        "id": to_int(project.id),
        "code": project.code,
        "name": project.name,
        "team_id": to_int(project.team_id),
        "team_name": team_map[project.team_id].name if project.team_id in team_map else None,
        "manager_id": to_int(project.manager_id) if project.manager_id else None,
        "manager_name": manager.real_name if manager else None,
        "start_date": fmt_date(project.start_date),
        "end_date": fmt_date(project.end_date),
        "status": project.status,
        "description": project.description,
        "created_at": fmt_dt(project.created_at),
        "members": serialized_members,
    }


async def create_project(db: AsyncSession, user: User, payload: Any) -> dict[str, Any]:
    import re

    if not re.fullmatch(r"[A-Z][A-Z0-9_]*", payload.code):
        raise BusinessValidationError("项目编码须为大写字母/数字/下划线且以字母开头")

    if user.role != "SUPER_ADMIN" and user.is_root != 1:
        # 行级安全：非管理员仅能在本团队下创建项目
        if user.team_id is None or payload.team_id != user.team_id:
            raise PermissionDeniedError("仅能创建本团队的项目")

    exists = await db.execute(select(Project).where(Project.code == payload.code))
    if exists.scalar_one_or_none():
        raise BusinessValidationError("项目编码已存在")

    team = await db.get(Team, payload.team_id)
    if team is None:
        raise BusinessValidationError("归属团队不存在")

    now = datetime.now()
    project = Project(
        team_id=payload.team_id,
        code=payload.code,
        name=payload.name,
        manager_id=payload.manager_id,
        start_date=payload.start_date,
        end_date=payload.end_date,
        status="IN_PROGRESS",
        description=payload.description,
        created_at=now,
        updated_at=now,
    )
    db.add(project)
    await db.commit()
    await db.refresh(project)
    return {"id": to_int(project.id), "code": project.code, "name": project.name}


async def update_project(db: AsyncSession, user: User, project_id: int, payload: Any) -> None:
    project = await db.get(Project, project_id)
    if project is None:
        raise ResourceNotFoundError("项目不存在")

    if user.role != "SUPER_ADMIN" and user.is_root != 1:
        # 行级安全：非管理员仅能更新本团队项目
        if user.team_id is None or project.team_id != user.team_id:
            raise ResourceNotFoundError("项目不存在")

    if payload.name is not None:
        project.name = payload.name
    if payload.manager_id is not None:
        project.manager_id = payload.manager_id
    if payload.start_date is not None:
        project.start_date = payload.start_date
    if payload.end_date is not None:
        project.end_date = payload.end_date
    if payload.status is not None:
        project.status = payload.status
    if payload.description is not None:
        project.description = payload.description
    project.updated_at = datetime.now()
    await db.commit()