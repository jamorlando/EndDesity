"""团队与组织架构业务服务。"""
from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import PermissionDeniedError, ResourceNotFoundError
from app.modules.auth.models import User
from app.modules.teams.models import Team
from app.utils.serializers import fmt_dt, to_int


async def _leader_name_map(db: AsyncSession, leader_ids: set[int]) -> dict[int, str]:
    if not leader_ids:
        return {}
    result = await db.execute(select(User.id, User.real_name).where(User.id.in_(leader_ids)))
    return {uid: name for uid, name in result.all()}


async def list_teams(db: AsyncSession) -> list[dict[str, Any]]:
    """团队列表卡片数据 (含主管名与在编人数)。"""
    teams = (await db.execute(select(Team).order_by(Team.id))).scalars().all()

    member_counts = dict(
        (await db.execute(
            select(User.team_id, func.count(User.id)).where(User.team_id.is_not(None)).group_by(User.team_id)
        )).all()
    )

    leader_ids = {t.leader_id for t in teams if t.leader_id}
    leader_map = await _leader_name_map(db, leader_ids)

    return [
        {
            "id": to_int(t.id),
            "code": t.code,
            "name": t.name,
            "description": t.description,
            "leader_id": to_int(t.leader_id) if t.leader_id else None,
            "leader_name": leader_map.get(t.leader_id),
            "member_count": member_counts.get(t.id, 0),
            "is_active": to_int(t.is_active),
            "created_at": fmt_dt(t.created_at),
        }
        for t in teams
    ]


async def get_team_detail(db: AsyncSession, team_id: int) -> dict[str, Any]:
    team = await db.get(Team, team_id)
    if team is None:
        raise ResourceNotFoundError("团队不存在")

    members_result = await db.execute(
        select(User).where(User.team_id == team_id).order_by(User.role, User.id)
    )
    members = [
        {
            "id": to_int(u.id),
            "username": u.username,
            "real_name": u.real_name,
            "email": u.email,
            "phone": u.phone,
            "role": u.role,
        }
        for u in members_result.scalars().all()
    ]

    leader_map = await _leader_name_map(db, {team.leader_id} if team.leader_id else set())

    return {
        "id": to_int(team.id),
        "code": team.code,
        "name": team.name,
        "description": team.description,
        "leader_id": to_int(team.leader_id) if team.leader_id else None,
        "leader_name": leader_map.get(team.leader_id),
        "member_count": len(members),
        "is_active": to_int(team.is_active),
        "created_at": fmt_dt(team.created_at),
        "members": members,
    }


async def create_team(db: AsyncSession, payload: Any) -> dict[str, Any]:
    import re

    if not re.fullmatch(r"[A-Z][A-Z0-9_]*", payload.code):
        from app.core.exceptions import BusinessValidationError

        raise BusinessValidationError("团队编码须为大写字母/数字/下划线且以字母开头")

    exists = await db.execute(select(Team).where(Team.code == payload.code))
    if exists.scalar_one_or_none():
        from app.core.exceptions import BusinessValidationError

        raise BusinessValidationError("团队编码已存在")

    now = datetime.now()
    team = Team(
        name=payload.name,
        code=payload.code,
        leader_id=payload.leader_id,
        description=payload.description,
        is_active=1,
        created_at=now,
        updated_at=now,
    )
    db.add(team)
    await db.commit()
    await db.refresh(team)
    return {"id": to_int(team.id), "code": team.code, "name": team.name}


async def update_team(db: AsyncSession, team_id: int, payload: Any) -> None:
    team = await db.get(Team, team_id)
    if team is None:
        raise ResourceNotFoundError("团队不存在")

    if payload.name is not None:
        team.name = payload.name
    if payload.description is not None:
        team.description = payload.description
    if payload.leader_id is not None:
        team.leader_id = payload.leader_id
    if payload.is_active is not None:
        team.is_active = payload.is_active
    team.updated_at = datetime.now()
    await db.commit()