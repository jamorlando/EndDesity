"""全局配置模块 —— 通过 pydantic-settings 读取 .env 环境变量。

敏感凭据（数据库连接串、JWT 密钥、大模型 API Key）一律存放于 .env 文件，
严禁硬编码于源码，遵循《项目开发规范与工程要求说明书》第 5 章节安全防线。
"""
from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """应用强类型配置。字段名不区分大小写，可从环境变量 / .env 覆盖。"""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "团队工作日志与智能复盘管理系统"
    app_version: str = "1.0.0"
    debug: bool = True

    # —— 数据库 (asyncmy 异步驱动) ——
    database_url: str = "mysql+asyncmy://root:123456@127.0.0.1:3306/end_design_db"

    # —— JWT 鉴权 ——
    jwt_secret_key: str = "end-design-jwt-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    # —— 大模型网关 ——
    llm_provider: str = "mock"          # mock | deepseek | qwen | openai
    llm_api_key: str = ""
    llm_base_url: str = ""
    llm_model: str = "deepseek-chat"

    # —— 跨域 ——
    cors_origins: str = "http://localhost:5173,http://127.0.0.1:5173"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


settings = Settings()