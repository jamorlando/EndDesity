"""工作日志模块请求模型。"""
from __future__ import annotations

from datetime import date
from typing import Any, Optional

from pydantic import BaseModel, Field


class WorkLogCreateRequest(BaseModel):
    template_id: int = 1
    project_id: Optional[int] = None
    log_date: date
    spent_hours: float = Field(..., ge=0, le=24)
    content_json: dict[str, Any] = Field(default_factory=dict)
    tag_ids: list[int] = Field(default_factory=list)


class WorkLogUpdateRequest(BaseModel):
    project_id: Optional[int] = None
    spent_hours: Optional[float] = None
    content_json: Optional[dict[str, Any]] = None
    tag_ids: Optional[list[int]] = None


class RollbackRequest(BaseModel):
    target_version: int
    reason: Optional[str] = None


class CommentRequest(BaseModel):
    content: str = Field(..., min_length=1)
    score_rating: Optional[int] = Field(None, ge=1, le=5)


class ScoreRequest(BaseModel):
    score: int = Field(..., ge=1, le=5)