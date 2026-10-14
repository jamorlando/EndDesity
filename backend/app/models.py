"""模型聚合注册口。

按依赖顺序导入全部 ORM 模型，确保 SQLAlchemy 在首次配置映射器前
已注册全部 22 张表（各模型仅以字符串外键弱耦合，杜绝循环导入）。
main.py 在应用启动时 import 本模块即可完成映射注册。
"""
from app.modules.auth.models import PasswordHistory, User
from app.modules.teams.models import Team
from app.modules.projects.models import Project, ProjectMember, WorkCalendar
from app.modules.work_logs.models import (
    Tag,
    WorkLog,
    WorkLogAttachment,
    WorkLogComment,
    WorkLogTagRel,
    WorkLogTemplate,
    WorkLogVersion,
)
from app.modules.retrospective.models import (
    RetrospectiveActionItem,
    RetrospectiveReport,
    RetrospectiveTemplate,
)
from app.integrations.ai.models import AiModelConfig, LlmCallLog
from app.modules.stats.models import AuditLog, DailyStatSnapshot
from app.modules.system.models import Notification, SystemConfig

__all__ = [
    "User",
    "PasswordHistory",
    "Team",
    "Project",
    "ProjectMember",
    "WorkCalendar",
    "Tag",
    "WorkLog",
    "WorkLogAttachment",
    "WorkLogComment",
    "WorkLogTagRel",
    "WorkLogTemplate",
    "WorkLogVersion",
    "RetrospectiveActionItem",
    "RetrospectiveReport",
    "RetrospectiveTemplate",
    "AiModelConfig",
    "LlmCallLog",
    "AuditLog",
    "DailyStatSnapshot",
    "Notification",
    "SystemConfig",
]