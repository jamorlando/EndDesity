"""智能复盘路由。"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.response import ok
from app.modules.auth.models import User
from app.modules.retrospective import service
from app.modules.retrospective.schemas import (
    ActionItemUpdateRequest,
    ReportCreateRequest,
    ReportUpdateRequest,
)

router = APIRouter(prefix="/retrospectives", tags=["智能复盘"])


@router.get("/action-items")
async def list_action_items(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return ok(await service.list_action_items(db, user))


@router.get("")
async def list_reports(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return ok(await service.list_reports(db, user, page, page_size))


@router.get("/{report_id}")
async def report_detail(
    report_id: int,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return ok(await service.get_report_detail(db, user, report_id))


@router.post("")
async def create_report(
    payload: ReportCreateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    data = await service.create_report(db, user, payload)
    return ok(data, "智能复盘报告生成成功")


@router.put("/{report_id}")
async def update_report(
    report_id: int,
    payload: ReportUpdateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    await service.update_report(db, user, report_id, payload)
    return ok(None, "复盘报告更新成功")


@router.put("/action-items/{item_id}")
async def update_action_item(
    item_id: int,
    payload: ActionItemUpdateRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    await service.update_action_item(db, user, item_id, payload)
    return ok(None, "行动项更新成功")