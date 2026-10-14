"""工作日志业务服务：填报、版本时光机、批注评分、热力图与卡点看板。"""
from __future__ import annotations

import calendar as _calendar
from datetime import date, datetime, timedelta
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BusinessValidationError, PermissionDeniedError, ResourceNotFoundError
from app.modules.auth.models import User
from app.modules.projects.models import Project, WorkCalendar
from app.modules.work_logs.models import (
    Tag,
    WorkLog,
    WorkLogComment,
    WorkLogTagRel,
    WorkLogTemplate,
    WorkLogVersion,
)
from app.utils.serializers import fmt_date, fmt_dt, to_float, to_int


def is_leader(user: User) -> bool:
    return user.role in ("SUPER_ADMIN", "TEAM_LEADER") or user.is_root == 1


def _assert_log_team(user: User, log: WorkLog) -> None:
    """行级安全：非超管只能操作本团队日志。"""
    if user.role == "SUPER_ADMIN" or user.is_root == 1:
        return
    if user.team_id is None or log.team_id != user.team_id:
        raise PermissionDeniedError("无权访问该团队日志")


async def _log_scope_team_ids(user: User) -> list[int]:
    if user.role == "SUPER_ADMIN" or user.is_root == 1:
        return []  # 空列表表示不限团队
    return [user.team_id] if user.team_id else []


async def _user_map(db: AsyncSession, user_ids: set[int]) -> dict[int, User]:
    if not user_ids:
        return {}
    result = await db.execute(select(User).where(User.id.in_(user_ids)))
    return {u.id: u for u in result.scalars().all()}


async def _project_map(db: AsyncSession, project_ids: set[int]) -> dict[int, Project]:
    if not project_ids:
        return {}
    result = await db.execute(select(Project).where(Project.id.in_(project_ids)))
    return {p.id: p for p in result.scalars().all()}


def _log_to_dict(log: WorkLog, user_map: dict, project_map: dict) -> dict[str, Any]:
    return {
        "id": to_int(log.id),
        "team_id": to_int(log.team_id),
        "user_id": to_int(log.user_id),
        "project_id": to_int(log.project_id) if log.project_id is not None else None,
        "template_id": to_int(log.template_id),
        "log_date": fmt_date(log.log_date),
        "content_json": log.content_json or {},
        "spent_hours": to_float(log.spent_hours),
        "is_delayed": to_int(log.is_delayed),
        "status": log.status,
        "current_version": to_int(log.current_version),
        "score": to_int(log.score) if log.score is not None else None,
        "author_name": user_map.get(log.user_id).real_name if log.user_id in user_map else None,
        "project_name": project_map.get(log.project_id).name if log.project_id in project_map else None,
        "created_at": fmt_dt(log.created_at),
        "updated_at": fmt_dt(log.updated_at),
    }


async def list_logs(db: AsyncSession, user: User, page: int, page_size: int) -> dict[str, Any]:
    team_ids = await _log_scope_team_ids(user)
    stmt = select(WorkLog)
    count_stmt = select(func.count(WorkLog.id))
    if team_ids:
        stmt = stmt.where(WorkLog.team_id.in_(team_ids))
        count_stmt = count_stmt.where(WorkLog.team_id.in_(team_ids))

    total = (await db.execute(count_stmt)).scalar_one()
    logs = (
        (await db.execute(
            stmt.order_by(WorkLog.log_date.desc(), WorkLog.id.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )).scalars().all()
    )

    user_ids = {l.user_id for l in logs}
    project_ids = {l.project_id for l in logs if l.project_id}
    user_map = await _user_map(db, user_ids)
    project_map = await _project_map(db, project_ids)

    items = [_log_to_dict(l, user_map, project_map) for l in logs]
    return {"items": items, "total": to_int(total)}


async def get_log_detail(db: AsyncSession, user: User, log_id: int) -> dict[str, Any]:
    log = await db.get(WorkLog, log_id)
    if log is None:
        raise ResourceNotFoundError("日志不存在")

    team_ids = await _log_scope_team_ids(user)
    if team_ids and log.team_id not in team_ids:
        raise ResourceNotFoundError("日志不存在")

    user_map = await _user_map(db, {log.user_id})
    project_map = await _project_map(db, {log.project_id} if log.project_id else set())
    data = _log_to_dict(log, user_map, project_map)

    # 版本时光机
    versions = (await db.execute(
        select(WorkLogVersion).where(WorkLogVersion.log_id == log_id).order_by(WorkLogVersion.version_num.desc())
    )).scalars().all()
    ver_user_ids = {v.operator_id for v in versions}
    ver_user_map = await _user_map(db, ver_user_ids)
    data["versions"] = [
        {
            "id": to_int(v.id),
            "version_num": to_int(v.version_num),
            "operator_name": ver_user_map.get(v.operator_id).real_name if v.operator_id in ver_user_map else None,
            "change_summary": v.change_summary,
            "is_rollback": to_int(v.is_rollback),
            "created_at": fmt_dt(v.created_at),
        }
        for v in versions
    ]

    # 评论批注
    comments = (await db.execute(
        select(WorkLogComment).where(WorkLogComment.log_id == log_id).order_by(WorkLogComment.created_at.desc())
    )).scalars().all()
    c_user_ids = {c.author_id for c in comments}
    c_user_map = await _user_map(db, c_user_ids)
    data["comments"] = [
        {
            "id": to_int(c.id),
            "author_name": c_user_map.get(c.author_id).real_name if c.author_id in c_user_map else None,
            "content": c.content,
            "score_rating": to_int(c.score_rating) if c.score_rating is not None else None,
            "created_at": fmt_dt(c.created_at),
        }
        for c in comments
    ]

    return data


async def _insert_version(
    db: AsyncSession, log: WorkLog, version_num: int, operator_id: int,
    content_json: dict, spent_hours: float, change_summary: str | None, is_rollback: int = 0,
) -> None:
    db.add(WorkLogVersion(
        log_id=log.id,
        version_num=version_num,
        operator_id=operator_id,
        content_json=content_json,
        spent_hours=spent_hours,
        change_summary=change_summary,
        is_rollback=is_rollback,
        created_at=datetime.now(),
    ))


async def _sync_tags(db: AsyncSession, log_id: int, tag_ids: list[int]) -> None:
    if tag_ids:
        for tag_id in set(tag_ids):
            db.add(WorkLogTagRel(log_id=log_id, tag_id=tag_id))


def _compute_delayed(log_date: date) -> int:
    return 1 if log_date < date.today() else 0


async def create_log(db: AsyncSession, user: User, payload: Any) -> dict[str, Any]:
    if user.team_id is None and not (user.role == "SUPER_ADMIN" or user.is_root == 1):
        raise BusinessValidationError("当前账号未归属团队，无法填报日志")

    template = await db.get(WorkLogTemplate, payload.template_id)
    if template is None:
        raise BusinessValidationError("日志模板不存在")

    # 同人同日仅一份日志
    exists = await db.execute(select(WorkLog).where(
        WorkLog.user_id == user.id, WorkLog.log_date == payload.log_date
    ))
    if exists.scalar_one_or_none():
        raise BusinessValidationError("该日期已填报日志，请勿重复提交")

    now = datetime.now()
    content_json = dict(payload.content_json or {})
    is_delayed = _compute_delayed(payload.log_date)
    log = WorkLog(
        team_id=user.team_id if user.team_id is not None else 1,
        user_id=user.id,
        project_id=payload.project_id,
        template_id=payload.template_id,
        log_date=payload.log_date,
        content_json=content_json,
        spent_hours=payload.spent_hours,
        is_delayed=is_delayed,
        status="NORMAL",
        current_version=1,
        score=None,
        created_at=now,
        updated_at=now,
    )
    db.add(log)
    await db.flush()
    await _insert_version(db, log, 1, user.id, content_json, payload.spent_hours, "初次提交日常研发工作产出与卡点汇报")
    await _sync_tags(db, log.id, payload.tag_ids or [])
    await db.commit()
    await db.refresh(log)
    return {"id": to_int(log.id), "is_delayed": is_delayed, "current_version": 1}


async def update_log(db: AsyncSession, user: User, log_id: int, payload: Any) -> None:
    log = await db.get(WorkLog, log_id)
    if log is None:
        raise ResourceNotFoundError("日志不存在")

    _assert_log_team(user, log)
    if log.user_id != user.id and not is_leader(user):
        raise PermissionDeniedError("无权修改他人日志")

    new_version = log.current_version + 1
    content_json = payload.content_json if payload.content_json is not None else log.content_json
    spent_hours = payload.spent_hours if payload.spent_hours is not None else log.spent_hours

    await _insert_version(db, log, new_version, user.id, log.content_json or {}, log.spent_hours, "编辑修订快照")

    if payload.project_id is not None:
        log.project_id = payload.project_id
    log.content_json = content_json
    log.spent_hours = spent_hours
    log.current_version = new_version
    log.updated_at = datetime.now()
    await db.commit()


async def rollback_log(db: AsyncSession, user: User, log_id: int, target_version: int, reason: str | None) -> None:
    log = await db.get(WorkLog, log_id)
    if log is None:
        raise ResourceNotFoundError("日志不存在")

    _assert_log_team(user, log)
    if log.user_id != user.id and not is_leader(user):
        raise PermissionDeniedError("无权操作他人日志")

    target = (await db.execute(select(WorkLogVersion).where(
        WorkLogVersion.log_id == log_id, WorkLogVersion.version_num == target_version
    ))).scalar_one_or_none()
    if target is None:
        raise BusinessValidationError("目标版本不存在")

    new_version = log.current_version + 1
    log.content_json = target.content_json or {}
    log.spent_hours = target.spent_hours
    log.current_version = new_version
    log.updated_at = datetime.now()
    await _insert_version(db, log, new_version, user.id, log.content_json, log.spent_hours,
                          reason or f"时光机回滚至 v{target_version}", is_rollback=1)
    await db.commit()


async def add_comment(db: AsyncSession, user: User, log_id: int, content: str, score_rating: int | None) -> None:
    log = await db.get(WorkLog, log_id)
    if log is None:
        raise ResourceNotFoundError("日志不存在")

    _assert_log_team(user, log)

    db.add(WorkLogComment(
        log_id=log_id,
        author_id=user.id,
        content=content,
        score_rating=score_rating,
        created_at=datetime.now(),
    ))
    await db.commit()


async def score_log(db: AsyncSession, user: User, log_id: int, score: int) -> None:
    if not is_leader(user):
        raise PermissionDeniedError("仅主管可评星打分")

    log = await db.get(WorkLog, log_id)
    if log is None:
        raise ResourceNotFoundError("日志不存在")

    _assert_log_team(user, log)

    log.score = score
    log.updated_at = datetime.now()
    await db.commit()


async def list_templates(db: AsyncSession, user: User) -> list[dict[str, Any]]:
    stmt = select(WorkLogTemplate).where(WorkLogTemplate.is_active == 1).order_by(WorkLogTemplate.id)
    team_ids = await _log_scope_team_ids(user)
    if team_ids:
        stmt = stmt.where(
            (WorkLogTemplate.team_id.is_(None)) | (WorkLogTemplate.team_id.in_(team_ids))
        )
    templates = (await db.execute(stmt)).scalars().all()
    return [
        {
            "id": to_int(t.id),
            "name": t.name,
            "code": t.code,
            "schema_json": t.schema_json or {},
            "is_default": to_int(t.is_default),
            "is_active": to_int(t.is_active),
        }
        for t in templates
    ]


async def list_tags(db: AsyncSession, user: User) -> list[dict[str, Any]]:
    stmt = select(Tag).where(Tag.is_active == 1).order_by(Tag.id)
    team_ids = await _log_scope_team_ids(user)
    if team_ids:
        stmt = stmt.where((Tag.team_id.is_(None)) | (Tag.team_id.in_(team_ids)))
    tags = (await db.execute(stmt)).scalars().all()
    return [
        {
            "id": to_int(t.id),
            "name": t.name,
            "color": t.color,
            "category": t.category,
            "is_active": to_int(t.is_active),
        }
        for t in tags
    ]


async def calendar_heatmap(db: AsyncSession, user: User, year: int, month: int) -> list[dict[str, Any]]:
    """个人月度出勤热力图。"""
    first = date(year, month, 1)
    days_in_month = _calendar.monthrange(year, month)[1]
    today = date.today()

    # 工作日历排班
    cal_rows = (await db.execute(select(WorkCalendar).where(
        WorkCalendar.calendar_date >= first,
        WorkCalendar.calendar_date < (date(year + 1, 1, 1) if month == 12 else date(year, month + 1, 1)),
    ))).scalars().all()
    cal_map = {c.calendar_date: c for c in cal_rows}

    # 当月本人日志
    log_rows = (await db.execute(select(WorkLog).where(
        WorkLog.user_id == user.id,
        WorkLog.log_date >= first,
        WorkLog.log_date < (date(year + 1, 1, 1) if month == 12 else date(year, month + 1, 1)),
    ))).scalars().all()
    log_map = {l.log_date: l for l in log_rows}

    out: list[dict[str, Any]] = []
    for day in range(1, days_in_month + 1):
        d = date(year, month, day)
        cal = cal_map.get(d)
        is_rest = cal.is_workday == 0 if cal else d.weekday() >= 5

        log = log_map.get(d)
        if is_rest:
            status = "rest"
        elif log is not None:
            status = "delayed" if to_int(log.is_delayed) == 1 else "submitted"
        elif d > today:
            status = "future"
        else:
            status = "absent"

        out.append({
            "date": fmt_date(d),
            "status": status,
            "log_id": to_int(log.id) if log is not None else None,
            "spent_hours": to_float(log.spent_hours) if log is not None else 0.0,
        })
    return out


async def blockers(db: AsyncSession, user: User) -> list[dict[str, Any]]:
    """团队近 14 天有卡点的日志 (汇入三关看板)。"""
    team_ids = await _log_scope_team_ids(user)
    since = date.today() - timedelta(days=14)
    stmt = select(WorkLog).where(WorkLog.log_date >= since)
    if team_ids:
        stmt = stmt.where(WorkLog.team_id.in_(team_ids))
    logs = (await db.execute(stmt.order_by(WorkLog.log_date.desc()))).scalars().all()

    user_map = await _user_map(db, {l.user_id for l in logs})
    project_map = await _project_map(db, {l.project_id for l in logs if l.project_id})

    out: list[dict[str, Any]] = []
    for log in logs:
        blocker_text = (log.content_json or {}).get("blockers")
        if not blocker_text or not str(blocker_text).strip():
            continue
        out.append({
            "log_id": to_int(log.id),
            "date": fmt_date(log.log_date),
            "blocker_text": blocker_text,
            "project_name": project_map.get(log.project_id).name if log.project_id in project_map else None,
            "author_name": user_map.get(log.user_id).real_name if log.user_id in user_map else None,
        })
    return out