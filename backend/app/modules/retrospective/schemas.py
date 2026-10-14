"""智能复盘模块请求模型。"""
from __future__ import annotations

from datetime import date
from typing import Optional

from pydantic import BaseModel, Field


class ReportCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=128)
    template_id: int = 1
    start_date: date
    end_date: date
    scope_type: str = "TEAM"


class ReportUpdateRequest(BaseModel):
    final_content: Optional[str] = None


class ActionItemUpdateRequest(BaseModel):
    status: Optional[str] = None
    result_summary: Optional[str] = None