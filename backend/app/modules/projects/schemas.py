"""项目模块请求模型。"""
from __future__ import annotations

from datetime import date
from typing import Optional

from pydantic import BaseModel, Field


class ProjectCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=128)
    code: str = Field(..., min_length=1, max_length=32)
    team_id: int
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    description: Optional[str] = None
    manager_id: Optional[int] = None


class ProjectUpdateRequest(BaseModel):
    name: Optional[str] = None
    manager_id: Optional[int] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    status: Optional[str] = None
    description: Optional[str] = None