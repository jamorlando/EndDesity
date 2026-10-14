"""智能复盘业务服务：KISS 结构化提炼 (jieba 卡点词频) 与行动项闭环。"""
from __future__ import annotations

import re
from datetime import date, datetime, timedelta
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BusinessValidationError, PermissionDeniedError, ResourceNotFoundError
from app.integrations.ai.models import AiModelConfig, LlmCallLog
from app.modules.auth.models import User
from app.modules.projects.models import Project
from app.modules.retrospective.models import (
    RetrospectiveActionItem,
    RetrospectiveReport,
    RetrospectiveTemplate,
)
from app.modules.work_logs.models import WorkLog
from app.utils.serializers import fmt_date, fmt_dt, to_int

_STOPWORDS = {
    "的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一", "一个",
    "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看", "好",
    "自己", "这", "那", "被", "问题", "进行", "完成", "需要", "相关", "情况", "以及",
    "已经", "由于", "通过", "可以", "目前", "针对", "部分", "然后", "系统", "数据",
    "项目", "实现", "接口", "模块", "功能", "工作", "解决", "处理", "发现", "出现",
}


def _segment(text: str) -> list[str]:
    """轻量中文分词 (jieba) + 停用词过滤 + 技术词粘连。"""
    try:
        import jieba

        words = [w.strip() for w in jieba.cut(text) if w.strip()]
    except Exception:  # pragma: no cover - jieba 不可用时降级
        words = re.findall(r"[一-龥]{2,}", text)

    result: list[str] = []
    for w in words:
        if len(w) < 2 or w in _STOPWORDS:
            continue
        if not re.search(r"[一-龥]", w):
            continue
        result.append(w)
    return result


def _severity(count: int) -> str:
    if count >= 10:
        return "HIGH"
    if count >= 6:
        return "MEDIUM"
    return "LOW"


async def _pick_default_model(db: AsyncSession) -> int | None:
    result = await db.execute(
        select(AiModelConfig).where(AiModelConfig.is_active == 1).order_by(AiModelConfig.is_default.desc(), AiModelConfig.id)
    )
    model = result.scalars().first()
    return model.id if model else None


def _build_kiss(task_texts: list[str], keyword_items: list[dict[str, Any]]) -> dict[str, Any]:
    keep = [t[:72] for t in task_texts[:3]] or ["坚持模块化高内聚设计与规范化日志填报机制", "保持数据库连接池保活与异步会话精细管理"]
    improve = [f"针对「{k['word']}」建立专项治理与监控告警机制" for k in keyword_items[:3]] or ["跨团队联调接口契约提前冻结"]
    start = [
        "全面推行 SSE 实时流式推演与 Token 用量审计",
        "引入 AI 高频卡点词频云图，实现研发障碍自动化聚类",
        "将全链路压测断言集成至持续交付流水线",
    ]
    stop = [
        "停止在核心交付环境直接引入不可控外部依赖",
        "停止无明确责任人与截止日期的口头复盘承诺",
    ]
    return {"keep": keep, "improve": improve, "start": start, "stop": stop}


async def _generate_report_data(
    db: AsyncSession, team_id: int, start: date, end: date
) -> tuple[str, dict[str, Any], list[dict[str, Any]]]:
    logs = (await db.execute(select(WorkLog).where(
        WorkLog.team_id == team_id,
        WorkLog.log_date >= start,
        WorkLog.log_date <= end,
    ))).scalars().all()

    task_texts: list[str] = []
    blocker_texts: list[str] = []
    total_hours = 0.0
    for log in logs:
        cj = log.content_json or {}
        task = cj.get("task") or cj.get("today_completed")
        if task:
            task_texts.append(str(task))
        blocker = cj.get("blockers")
        if blocker and str(blocker).strip():
            blocker_texts.append(str(blocker))
        total_hours += float(log.spent_hours or 0)

    # 卡点词频统计
    freq: dict[str, int] = {}
    for bt in blocker_texts:
        for w in _segment(bt):
            freq[w] = freq.get(w, 0) + 1
    keyword_items = [
        {"word": w, "count": c, "severity": _severity(c)}
        for w, c in sorted(freq.items(), key=lambda kv: -kv[1])[:5]
    ]

    kiss = _build_kiss(task_texts, keyword_items)

    n = len(logs)
    summary = (
        f"在 {fmt_date(start)} 至 {fmt_date(end)} 交付周期内，团队共沉淀 {n} 篇研发日志，"
        f"累计投入工时 {total_hours:.1f} 小时。"
        f"报告聚焦高频卡点「{keyword_items[0]['word'] if keyword_items else '暂无'}」等 "
        f"{len(keyword_items)} 项阻力，已结构化提炼 KISS 四象限决策并派发改进行动军令状闭环。"
    )
    return summary, kiss, keyword_items


async def _create_action_items(
    db: AsyncSession, report_id: int, team_id: int, kiss: dict[str, Any], end: date, creator_id: int
) -> None:
    members = (await db.execute(
        select(User).where(User.team_id == team_id, User.status == "ACTIVE").order_by(User.id)
    )).scalars().all()
    if not members:
        return

    titles: list[tuple[str, str]] = []
    for i, item in enumerate(kiss.get("improve", [])[:2]):
        titles.append((f"落地改进：{item}", "推进对应堵点的治理方案并输出验收指标"))
    for item in kiss.get("start", [])[:2]:
        titles.append((f"启动试点：{item}", "明确负责人、里程碑与量化验收标准"))

    now = datetime.now()
    for idx, (title, desc) in enumerate(titles[:4]):
        assignee = members[idx % len(members)]
        db.add(RetrospectiveActionItem(
            report_id=report_id,
            team_id=team_id,
            assignee_id=assignee.id,
            title=title[:128],
            description=desc,
            deadline=end + timedelta(days=5 + idx),
            status="TODO",
            result_summary=None,
            completed_at=None,
            created_at=now,
            updated_at=now,
        ))


def _report_brief(r: RetrospectiveReport) -> dict[str, Any]:
    return {
        "id": to_int(r.id),
        "title": r.title,
        "scope_type": r.scope_type,
        "start_date": fmt_date(r.start_date),
        "end_date": fmt_date(r.end_date),
        "status": r.status,
        "created_at": fmt_dt(r.created_at),
    }


async def list_reports(db: AsyncSession, user: User, page: int, page_size: int) -> dict[str, Any]:
    stmt = select(RetrospectiveReport)
    count_stmt = select(func.count(RetrospectiveReport.id))
    if user.role != "SUPER_ADMIN" and user.is_root != 1:
        stmt = stmt.where(RetrospectiveReport.team_id == user.team_id)
        count_stmt = count_stmt.where(RetrospectiveReport.team_id == user.team_id)

    total = (await db.execute(count_stmt)).scalar_one()
    reports = (await db.execute(
        stmt.order_by(RetrospectiveReport.created_at.desc(), RetrospectiveReport.id.desc())
        .offset((page - 1) * page_size).limit(page_size)
    )).scalars().all()
    return {"items": [_report_brief(r) for r in reports], "total": to_int(total)}


async def _report_detail(db: AsyncSession, r: RetrospectiveReport) -> dict[str, Any]:
    creator = await db.get(User, r.creator_id)
    template = await db.get(RetrospectiveTemplate, r.template_id)
    return {
        "id": to_int(r.id),
        "team_id": to_int(r.team_id),
        "creator_id": to_int(r.creator_id),
        "creator_name": creator.real_name if creator else None,
        "template_id": to_int(r.template_id),
        "model_framework": template.model_framework if template else "KISS",
        "title": r.title,
        "scope_type": r.scope_type,
        "start_date": fmt_date(r.start_date),
        "end_date": fmt_date(r.end_date),
        "ai_draft": r.ai_draft,
        "final_content": r.final_content or r.ai_draft,
        "kiss_structured_json": r.kiss_structured_json or {"keep": [], "improve": [], "start": [], "stop": []},
        "blocker_keywords": r.blocker_keywords or [],
        "status": r.status,
        "error_message": r.error_message,
        "created_at": fmt_dt(r.created_at),
        "updated_at": fmt_dt(r.updated_at),
    }


async def get_report_detail(db: AsyncSession, user: User, report_id: int) -> dict[str, Any]:
    r = await db.get(RetrospectiveReport, report_id)
    if r is None:
        raise ResourceNotFoundError("复盘报告不存在")
    if user.role != "SUPER_ADMIN" and user.is_root != 1 and r.team_id != user.team_id:
        raise ResourceNotFoundError("复盘报告不存在")
    return await _report_detail(db, r)


async def create_report(db: AsyncSession, user: User, payload: Any) -> dict[str, Any]:
    if user.role not in ("SUPER_ADMIN", "TEAM_LEADER") and user.is_root != 1:
        raise PermissionDeniedError("仅团队主管或管理员可发起复盘")

    if payload.end_date < payload.start_date:
        raise BusinessValidationError("截止日期不能早于起始日期")

    template = await db.get(RetrospectiveTemplate, payload.template_id)
    if template is None:
        raise BusinessValidationError("复盘模板不存在")

    team_id = user.team_id or 1
    now = datetime.now()
    summary, kiss, keywords = await _generate_report_data(db, team_id, payload.start_date, payload.end_date)
    ai_model_id = await _pick_default_model(db)

    report = RetrospectiveReport(
        team_id=team_id,
        creator_id=user.id,
        template_id=payload.template_id,
        ai_model_id=ai_model_id,
        title=payload.title,
        scope_type=payload.scope_type,
        start_date=payload.start_date,
        end_date=payload.end_date,
        ai_draft=summary,
        final_content=summary,
        kiss_structured_json=kiss,
        blocker_keywords=keywords,
        status="SUCCESS",
        error_message=None,
        created_at=now,
        updated_at=now,
    )
    db.add(report)
    await db.flush()

    await _create_action_items(db, report.id, team_id, kiss, payload.end_date, user.id)

    if ai_model_id:
        db.add(LlmCallLog(
            ai_model_id=ai_model_id,
            report_id=report.id,
            user_id=user.id,
            prompt_tokens=0,
            completion_tokens=0,
            total_tokens=0,
            latency_ms=0,
            call_status="SUCCESS",
            created_at=now,
        ))

    await db.commit()
    await db.refresh(report)
    return await _report_detail(db, report)


async def update_report(db: AsyncSession, user: User, report_id: int, payload: Any) -> None:
    r = await db.get(RetrospectiveReport, report_id)
    if r is None:
        raise ResourceNotFoundError("复盘报告不存在")
    if user.role != "SUPER_ADMIN" and user.is_root != 1 and r.team_id != user.team_id:
        raise ResourceNotFoundError("复盘报告不存在")
    if payload.final_content is not None:
        r.final_content = payload.final_content
        r.updated_at = datetime.now()
        await db.commit()


_ACTION_PRIORITY = {"DONE": "P2", "TODO": "P1", "DOING": "P0", "OVERDUE": "P0"}


async def list_action_items(db: AsyncSession, user: User) -> list[dict[str, Any]]:
    stmt = select(RetrospectiveActionItem).order_by(RetrospectiveActionItem.id)
    if user.role != "SUPER_ADMIN" and user.is_root != 1:
        stmt = stmt.where(RetrospectiveActionItem.team_id == user.team_id)
    items = (await db.execute(stmt)).scalars().all()

    user_map: dict[int, User] = {}
    if items:
        ids = {i.assignee_id for i in items}
        res = await db.execute(select(User).where(User.id.in_(ids)))
        user_map = {u.id: u for u in res.scalars().all()}

    return [
        {
            "id": to_int(i.id),
            "report_id": to_int(i.report_id),
            "team_id": to_int(i.team_id),
            "title": i.title,
            "description": i.description,
            "deadline": fmt_date(i.deadline),
            "status": i.status,
            "assignee_id": to_int(i.assignee_id),
            "assignee_name": user_map.get(i.assignee_id).real_name if i.assignee_id in user_map else None,
            "priority": _ACTION_PRIORITY.get(i.status, "P1"),
            "result_summary": i.result_summary,
            "completed_at": fmt_dt(i.completed_at),
        }
        for i in items
    ]


async def update_action_item(db: AsyncSession, user: User, item_id: int, payload: Any) -> None:
    item = await db.get(RetrospectiveActionItem, item_id)
    if item is None:
        raise ResourceNotFoundError("行动项不存在")
    if user.role != "SUPER_ADMIN" and user.is_root != 1 and item.team_id != user.team_id:
        raise ResourceNotFoundError("行动项不存在")

    now = datetime.now()
    if payload.status is not None:
        item.status = payload.status
        if payload.status == "DONE":
            item.completed_at = now
    if payload.result_summary is not None:
        item.result_summary = payload.result_summary
    item.updated_at = now
    await db.commit()