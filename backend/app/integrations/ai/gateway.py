"""大模型统一网关 (mock 提供方 + SSE 流式打字机)。"""
from __future__ import annotations

import asyncio
import json
from typing import AsyncGenerator

_MOCK_BLUEPRINT = """【AI 研发效能推演中枢 · 分析报告】

你好，我是企业研发智能助手。针对你输入的推演指令，我已完成如下多维度研判：

一、问题定位
结合当前团队工作日志沉淀与工时数据，核心瓶颈集中于「{prompt}」所涉及的工程链路。

二、攻坚策略
1. 先建立可观测基线：补齐日志埋点与指标告警，锁定真实卡点位置。
2. 采用最小闭环验证：以低风险灰度方式推进变更，回滚预案前置准备。
3. 沉淀防回归自动化：将关键断言接入持续交付流水线。

三、预防与沉淀
建议将本次推演结论同步到 KISS 复盘看板，明确责任人与截止日期，形成可追溯的改进军令状。

以上结论已同步写入本地高仿真沙箱（离线可用），如需进一步展开某一维度可继续追问。"""


def build_mock_text(prompt: str) -> str:
    safe = (prompt or "研发效能优化").strip() or "研发效能优化"
    if len(safe) > 40:
        safe = safe[:40] + "…"
    return _MOCK_BLUEPRINT.format(prompt=safe)


async def stream_chat(prompt: str) -> AsyncGenerator[str, None]:
    """按 SSE 协议逐段产出 data: {chunk} 帧，最后发送 [DONE]。"""
    text = build_mock_text(prompt)
    # 以 3 字符为单位模拟打字机流式输出
    step = 3
    for i in range(0, len(text), step):
        chunk = text[i:i + step]
        yield f"data: {json.dumps({'chunk': chunk}, ensure_ascii=False)}\n\n"
        await asyncio.sleep(0.02)
    yield "data: [DONE]\n\n"