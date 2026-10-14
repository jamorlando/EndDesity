"""效能度量大屏路由。"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.response import ok
from app.modules.auth.models import User
from app.modules.stats import service

router = APIRouter(prefix="/stats", tags=["效能度量"])


@router.get("/overview")
async def overview(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return ok(await service.overview(db, user))


@router.get("/burn-down")
async def burn_down(
    days: int = Query(14, ge=1, le=60),
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return ok(await service.burn_down(db, user, days))


@router.get("/radar")
async def radar(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return ok(await service.radar(db, user))


@router.get("/snapshots")
async def snapshots(
    limit: int = Query(15, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return ok(await service.snapshots(db, user, limit))