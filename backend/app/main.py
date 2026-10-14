"""FastAPI 应用入口：装配中间件、全局异常、路由注册与健康检查。

遵循《项目开发规范与工程要求说明书》Package-by-Feature 架构，
所有业务路由以 /api/v1 为统一前缀对前端暴露。
"""
from __future__ import annotations

import logging

from fastapi import FastAPI, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware

import app.models  # noqa: F401  确保 22 张表映射注册
from app.core.config import settings
from app.core.exceptions import AppException
from app.core.response import fail, ok
from app.integrations.ai.router import router as ai_router
from app.modules.auth.router import router as auth_router
from app.modules.projects.router import router as projects_router
from app.modules.retrospective.router import router as retrospective_router
from app.modules.stats.router import router as stats_router
from app.modules.teams.router import router as teams_router
from app.modules.work_logs.router import router as work_logs_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    docs_url="/api/docs",
    openapi_url="/api/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# 全局异常处理器
# ---------------------------------------------------------------------------
@app.exception_handler(AppException)
async def _app_exception_handler(request, exc: AppException):
    return fail(exc.status_code, exc.message, exc.code)


@app.exception_handler(RequestValidationError)
async def _validation_exception_handler(request, exc: RequestValidationError):
    first = exc.errors()[0] if exc.errors() else {}
    loc = ".".join(str(x) for x in first.get("loc", []) if x != "body")
    msg = first.get("msg", "请求参数校验失败")
    return fail(422, f"参数校验失败：{loc} {msg}".strip(), 422)


@app.exception_handler(HTTPException)
async def _http_exception_handler(request, exc: HTTPException):
    return fail(exc.status_code, exc.detail, exc.status_code)


@app.exception_handler(Exception)
async def _generic_exception_handler(request, exc: Exception):
    logger.exception("未捕获异常: %s", exc, exc_info=exc)
    return fail(500, "服务器内部错误，请稍后重试", 500)


# ---------------------------------------------------------------------------
# 路由注册
# ---------------------------------------------------------------------------
API_PREFIX = "/api/v1"
app.include_router(auth_router, prefix=API_PREFIX)
app.include_router(teams_router, prefix=API_PREFIX)
app.include_router(projects_router, prefix=API_PREFIX)
app.include_router(work_logs_router, prefix=API_PREFIX)
app.include_router(retrospective_router, prefix=API_PREFIX)
app.include_router(stats_router, prefix=API_PREFIX)
app.include_router(ai_router, prefix=API_PREFIX)


@app.get("/api/v1/health", tags=["系统"])
async def health():
    return ok({"status": "UP", "app": settings.app_name, "version": settings.app_version})


@app.get("/health", tags=["系统"])
async def health_bare():
    return ok({"status": "UP"})