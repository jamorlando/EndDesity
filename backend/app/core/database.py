"""数据库异步引擎与会话工厂 (SQLAlchemy 2.0 async)。

采用 asyncmy 驱动连接 MySQL 8.0，配置 pool_pre_ping / pool_recycle 保活参数，
避免 8 小时空闲断连与连接泄漏问题。
"""
from __future__ import annotations

from sqlalchemy.engine import URL
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings


class Base(DeclarativeBase):
    """全项目 ORM 模型统一基类，共享同一 MetaData。"""


def _build_database_url() -> str:
    """兼容从单行 URL 或分字段环境变量构造连接串。"""
    if settings.database_url.startswith(("mysql+asyncmy://", "mysql+aiomysql://")):
        return settings.database_url
    return str(
        URL.create(
            drivername="mysql+asyncmy",
            username="root",
            password="123456",
            host="127.0.0.1",
            port=3306,
            database="end_design_db",
        )
    )


engine = create_async_engine(
    _build_database_url(),
    echo=False,
    pool_pre_ping=True,
    pool_recycle=3600,
    pool_size=10,
    max_overflow=20,
    future=True,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)