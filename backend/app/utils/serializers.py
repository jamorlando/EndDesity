"""通用独立工具库：ORM 对象序列化辅助函数。

将 datetime/date 统一格式化为与前端展示一致的字符串 (空格分隔，无 T 字符)，
并保持布尔类 TINYINT 字段输出为 0/1 整数，确保前端严格等价比较成立。
"""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Any


def fmt_dt(value: Any) -> str:
    """格式化 datetime -> 'YYYY-MM-DD HH:MM:SS'。"""
    if value is None:
        return ""
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d %H:%M:%S")
    return str(value)


def fmt_date(value: Any) -> str:
    """格式化 date/datetime -> 'YYYY-MM-DD'。"""
    if value is None:
        return ""
    if isinstance(value, (date, datetime)):
        return value.strftime("%Y-%m-%d")
    return str(value)


def to_float(value: Any, default: float = 0.0) -> float:
    """安全转 float (Decimal/Float/None)。"""
    if value is None:
        return default
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def to_int(value: Any, default: int = 0) -> int:
    """安全转 int (TINYINT 返回 0/1)。"""
    if value is None:
        return default
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def as_dict(value: Any) -> Any:
    """JSON 字段已由 asyncmy 反序列化，直接透传；None/Decimal 兜底。"""
    if value is None:
        return None
    if isinstance(value, Decimal):
        return float(value)
    return value