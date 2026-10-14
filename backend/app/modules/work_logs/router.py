"""工作日志路由 (静态资源路由须先于 /{log_id} 声明)。"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.response import ok
from app.modules.auth.models import User
from app.modules.work_logs import service
from app.modules.work_logs.schemas import (
    CommentRequest,
    RollbackRequest,
    ScoreRequest,
    WorkLogCreateRequest,
    WorkLogUpdateRequest,
)

router = APIRouter(prefix="/work-logs", tags=["工作日志"])


@router.get("/templates")
async def list_templates(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return ok(await service.list_templates(db, user))


@router.get("/tags")
async def list_tags(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return ok(await service.list_tags(db, user))


@router.get("/calendar-heatmap")
async def calendar_heatmap(
    year: int = Query(...),
    month: int = Query(...),
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return ok(await service.calendar_heatmap(db, user, year, month))


@router.get("/blockers")
async def blockers(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return ok(await service.blockers(db, user))


@router.get("")
async def list_logs(
    page: int = Query(1, ge=1),
    page_size: int = Query(30, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return ok(await service.list_logs(db, user, page, page_size))


@router.get("/{log_id}")
async def log_detail(log_id: int, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return ok(await service.get_log_detail(db, user, log_id))


@router.post("")
async def create_log(
    payload: WorkLogCreateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    data = await service.create_log(db, user, payload)
    return ok(data, "日志提交成功")


@router.put("/{log_id}")
async def update_log(
    log_id: int,
    payload: WorkLogUpdateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    await service.update_log(db, user, log_id, payload)
    return ok(None, "日志更新成功")


@router.post("/{log_id}/rollback")
async def rollback_log(
    log_id: int,
    payload: RollbackRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    await service.rollback_log(db, user, log_id, payload.target_version, payload.reason)
    return ok(None, "时光机回滚成功")


@router.post("/{log_id}/comments")
async def add_comment(
    log_id: int,
    payload: CommentRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    await service.add_comment(db, user, log_id, payload.content, payload.score_rating)
    return ok(None, "批注发表成功")


@router.post("/{log_id}/score")
async def score_log(
    log_id: int,
    payload: ScoreRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    await service.score_log(db, user, log_id, payload.score)
    return ok(None, "评分已保存")