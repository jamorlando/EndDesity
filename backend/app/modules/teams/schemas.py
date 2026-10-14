"""团队模块请求模型。"""
from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


class TeamCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=64)
    code: str = Field(..., min_length=1, max_length=32)
    description: Optional[str] = None
    leader_id: Optional[int] = None


class TeamUpdateRequest(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    leader_id: Optional[int] = None
    is_active: Optional[int] = None