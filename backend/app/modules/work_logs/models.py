"""工作日志核心实体模型。

tables: work_log_templates, tags, work_logs, work_log_tag_rel,
        work_log_versions, work_log_attachments, work_log_comments
"""
from __future__ import annotations

from datetime import date, datetime
from typing import Optional

from sqlalchemy import (
    BigInteger,
    Date,
    DateTime,
    Float,
    ForeignKey,
    JSON,
    SmallInteger,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class WorkLogTemplate(Base):
    __tablename__ = "work_log_templates"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    team_id: Mapped[Optional[int]] = mapped_column(BigInteger, ForeignKey("teams.id", ondelete="CASCADE"), nullable=True)
    name: Mapped[str] = mapped_column(String(64), nullable=False)
    code: Mapped[str] = mapped_column(String(32), nullable=False)
    schema_json: Mapped[dict] = mapped_column(JSON, nullable=False)
    is_default: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    is_active: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)


class Tag(Base):
    __tablename__ = "tags"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    team_id: Mapped[Optional[int]] = mapped_column(BigInteger, ForeignKey("teams.id", ondelete="CASCADE"), nullable=True)
    name: Mapped[str] = mapped_column(String(32), nullable=False)
    color: Mapped[str] = mapped_column(String(16), nullable=False, default="#409EFF")
    category: Mapped[str] = mapped_column(String(32), nullable=False, default="TASK_TYPE")
    is_active: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)


class WorkLog(Base):
    __tablename__ = "work_logs"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    team_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("teams.id", ondelete="RESTRICT"), nullable=False)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    project_id: Mapped[Optional[int]] = mapped_column(BigInteger, ForeignKey("projects.id", ondelete="SET NULL"), nullable=True)
    template_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("work_log_templates.id", ondelete="RESTRICT"), nullable=False)
    log_date: Mapped[date] = mapped_column(Date, nullable=False)
    content_json: Mapped[dict] = mapped_column(JSON, nullable=False)
    spent_hours: Mapped[float] = mapped_column(Float, nullable=False, default=8.0)
    is_delayed: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="NORMAL")
    current_version: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    score: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)


class WorkLogTagRel(Base):
    __tablename__ = "work_log_tag_rel"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    log_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("work_logs.id", ondelete="CASCADE"), nullable=False)
    tag_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("tags.id", ondelete="RESTRICT"), nullable=False)


class WorkLogVersion(Base):
    __tablename__ = "work_log_versions"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    log_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("work_logs.id", ondelete="CASCADE"), nullable=False)
    version_num: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    operator_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    content_json: Mapped[dict] = mapped_column(JSON, nullable=False)
    spent_hours: Mapped[float] = mapped_column(Float, nullable=False)
    change_summary: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    is_rollback: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)


class WorkLogAttachment(Base):
    __tablename__ = "work_log_attachments"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    log_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("work_logs.id", ondelete="CASCADE"), nullable=False)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    original_name: Mapped[str] = mapped_column(String(255), nullable=False)
    stored_name: Mapped[str] = mapped_column(String(128), nullable=False)
    file_path: Mapped[str] = mapped_column(String(512), nullable=False)
    file_size: Mapped[int] = mapped_column(BigInteger, nullable=False)
    mime_type: Mapped[str] = mapped_column(String(128), nullable=False)
    file_ext: Mapped[str] = mapped_column(String(16), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)


class WorkLogComment(Base):
    __tablename__ = "work_log_comments"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    log_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("work_logs.id", ondelete="CASCADE"), nullable=False)
    author_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    score_rating: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)