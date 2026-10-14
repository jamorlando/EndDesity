# -*- coding: utf-8 -*-
"""后端全链路严格测试：契约、序列化、鉴权、越权、校验、SSE 与写回清理。

运行: cd backend && python _strict_test.py
"""
import re
import sys

for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8")
    except Exception:
        pass

import httpx

BASE = "http://127.0.0.1:8000/api/v1"
PASS = 0
FAIL = 0
FAILED = []


def check(name: str, cond: bool, detail: str = ""):
    global PASS, FAIL
    if cond:
        PASS += 1
        print(f"  [OK] {name}")
    else:
        FAIL += 1
        FAILED.append(name)
        print(f"  [XX] {name}  {detail}")


def login(c: httpx.Client, username: str, password: str = "123456"):
    return c.post("/auth/login", json={"username": username, "password": password})


def auth_header(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


DT = r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$"
D = r"^\d{4}-\d{2}-\d{2}$"


def is_dt(s): return isinstance(s, str) and bool(re.fullmatch(DT, s))


def is_d(s): return isinstance(s, str) and bool(re.fullmatch(D, s))


def main():
    c = httpx.Client(base_url=BASE, timeout=30)
    created = {"logs": [], "reports": [], "projects": [], "teams": [], "stream_user": None}

    # ---------- 0. 健康检查 / 未认证 ----------
    print("\n== 健康检查 / 未认证 ==")
    r = c.get("/health")
    check("GET /health 200 + envelope", r.status_code == 200 and r.json()["data"]["status"] == "UP")
    r = c.get("/auth/me")
    check("无 Token 访问 /auth/me -> 401", r.status_code == 401, str(r.status_code))
    r = c.get("/auth/me", headers=auth_header("garbage.token.here"))
    check("伪造 Token -> 401", r.status_code == 401, str(r.status_code))

    # ---------- 1. 登录 ----------
    print("\n== 登录 ==")
    rl = login(c, "root")
    check("root 登录 200", rl.status_code == 200, str(rl.text[:200]))
    body = rl.json()
    check("成功响应四字段 {code,message,data,timestamp}", set(body) == {"code", "message", "data", "timestamp"})
    check("code=200 且 message 非空", body["code"] == 200 and body["message"])
    data = body["data"]
    check("含 access/refresh/token_type/user", {"access_token", "refresh_token", "token_type", "user"} <= set(data))
    u = data["user"]
    check("user.is_root 为整数", isinstance(u["is_root"], int) and u["is_root"] == 1, repr(u.get("is_root")))
    check("user.id 为整数且 role=SUPER_ADMIN", isinstance(u["id"], int) and u["role"] == "SUPER_ADMIN")
    check("user.team_id 为 None (root)", u["team_id"] is None, repr(u.get("team_id")))
    check("user.created_at 为时间戳字符串", is_dt(u["created_at"]), repr(u.get("created_at")))
    root_token = data["access_token"]
    root_refresh = data["refresh_token"]

    r = login(c, "root", "wrongpass")
    check("错误密码 -> 401", r.status_code == 401, str(r.status_code))
    r = login(c, "nobody", "123456")
    check("不存在用户 -> 401", r.status_code == 401, str(r.status_code))

    # 各角色登录
    tokens = {}
    for uname, rid in [("leader_zhang", 2), ("leader_li", 3), ("dev_chen", 5), ("dev_liu", 7), ("qa_sun", 8), ("dev_zhou", 10)]:
        rr = login(c, uname)
        assert rr.status_code == 200, f"{uname} 登录失败 {rr.text[:200]}"
        tokens[uname] = rr.json()["data"]
        check(f"{uname} 登录成功且 user.id={rid}", tokens[uname]["user"]["id"] == rid)

    # ---------- 2. refresh ----------
    print("\n== 令牌刷新 ==")
    r = c.post("/auth/refresh", json={"refresh_token": root_refresh})
    check("refresh 200 返回新令牌", r.status_code == 200 and "access_token" in r.json()["data"])
    r = c.post("/auth/refresh", json={"refresh_token": root_token})
    check("用 access 刷 refresh -> 401", r.status_code == 401, str(r.status_code))

    # ---------- 3. me ----------
    print("\n== 当前用户 ==")
    r = c.get("/auth/me", headers=auth_header(root_token))
    check("GET /auth/me 200", r.status_code == 200 and r.json()["data"]["username"] == "root")
    r = c.get("/auth/me", headers=auth_header(tokens["dev_chen"]["access_token"]))
    check("dev_chen me: team_id=1, role=MEMBER, is_root=0",
          r.json()["data"]["team_id"] == 1 and r.json()["data"]["role"] == "MEMBER"
          and r.json()["data"]["is_root"] == 0)

    # ---------- 4. change-password (仅错误路径，避免锁定) ----------
    print("\n== 改密错误路径 ==")
    h = auth_header(tokens["dev_liu"]["access_token"])
    r = c.post("/auth/change-password", headers=h, json={"old_password": "bad", "new_password": "abcdef123"})
    check("原密码错误 -> 400", r.status_code == 400, str(r.status_code))
    r = c.post("/auth/change-password", headers=h, json={"old_password": "123456", "new_password": "123456"})
    check("新旧相同 -> 400", r.status_code == 400, str(r.status_code))
    r = c.post("/auth/change-password", headers=h, json={"old_password": "123456", "new_password": "123"})
    check("新密码过短 -> 422", r.status_code == 422, str(r.status_code))
    # 登出
    r = c.post("/auth/logout", headers=h)
    check("POST /auth/logout 200", r.status_code == 200)

    # ---------- 5. teams ----------
    print("\n== 团队 ==")
    r = c.get("/teams", headers=auth_header(root_token))
    teams = r.json()["data"]
    check("GET /teams 裸数组 + 5 条", r.status_code == 200 and isinstance(teams, list) and len(teams) == 5)
    t0 = teams[0]
    check("team 字段齐 + 类型正确",
          isinstance(t0["id"], int) and isinstance(t0["member_count"], int)
          and isinstance(t0["is_active"], int) and is_dt(t0["created_at"])
          and isinstance(t0["leader_id"], int) and isinstance(t0["leader_name"], str))
    r = c.get("/teams/1", headers=auth_header(root_token))
    d1 = r.json()["data"]
    check("GET /teams/1 含 members 数组", isinstance(d1["members"], list) and len(d1["members"]) >= 2)
    r = c.get("/teams/9999", headers=auth_header(root_token))
    check("GET /teams/9999 -> 404", r.status_code == 404)
    # 权限：成员不能创建团队
    r = c.post("/teams", headers=auth_header(tokens["dev_chen"]["access_token"]),
               json={"name": "X", "code": "ZZTEST"})
    check("MEMBER 创建团队 -> 403", r.status_code == 403, str(r.status_code))
    # 校验：非法 code
    r = c.post("/teams", headers=auth_header(root_token), json={"name": "X", "code": "bad code"})
    check("非法团队 code -> 400", r.status_code == 400, str(r.status_code))

    # ---------- 6. projects ----------
    print("\n== 项目 ==")
    r = c.get("/projects", headers=auth_header(root_token))
    projs = r.json()["data"]
    check("GET /projects 裸数组 root 见 5 条", isinstance(projs, list) and len(projs) == 5)
    p0 = projs[0]
    check("project 字段类型正确", isinstance(p0["id"], int) and isinstance(p0["team_id"], int)
          and isinstance(p0["manager_id"], int) and is_d(p0["start_date"]) and is_dt(p0["created_at"]))
    r = c.get("/projects", headers=auth_header(tokens["dev_chen"]["access_token"]))
    check("dev_chen(团队1) 仅见团队1项目", all(p["team_id"] == 1 for p in r.json()["data"]) and len(r.json()["data"]) == 1)
    # 越权读取
    r = c.get("/projects/2", headers=auth_header(tokens["dev_chen"]["access_token"]))
    check("dev_chen 读团队2项目 -> 404", r.status_code == 404, str(r.status_code))
    # 成员不能建项目
    r = c.post("/projects", headers=auth_header(tokens["dev_chen"]["access_token"]),
               json={"name": "X", "code": "ZZTESTP", "team_id": 1})
    check("MEMBER 建项目 -> 403", r.status_code == 403, str(r.status_code))

    # ---------- 7. work-logs 读 ----------
    print("\n== 工作日志读 ==")
    h_root = auth_header(root_token)
    h_chen = auth_header(tokens["dev_chen"]["access_token"])
    r = c.get("/work-logs", headers=h_root, params={"page": 1, "page_size": 50})
    wl = r.json()["data"]
    check("GET /work-logs 返回 {items,total}", isinstance(wl, dict) and {"items", "total"} <= set(wl)
          and isinstance(wl["items"], list) and isinstance(wl["total"], int))
    total = wl["total"]
    check("日志总数 >= 19", total >= 19, str(wl.get("total")))
    if wl["items"]:
        it = wl["items"][0]
        check("日志字段类型正确",
              isinstance(it["id"], int) and is_d(it["log_date"]) and isinstance(it["spent_hours"], (int, float))
              and isinstance(it["is_delayed"], int) and isinstance(it["author_name"], str)
              and is_dt(it["created_at"]))
        check("score 为 1-5 整数或 None/0", it["score"] is None or (isinstance(it["score"], int) and 1 <= it["score"] <= 5),
              repr(it.get("score")))
    # 团队隔离：dev_liu(团队2) 只能见团队2
    r = c.get("/work-logs", headers=auth_header(tokens["dev_liu"]["access_token"]), params={"page_size": 100})
    liu_items = r.json()["data"]["items"]
    check("dev_liu 仅见团队2日志", all(i["team_id"] == 2 for i in liu_items), f"{len(liu_items)} items")
    # 模板 / 标签
    r = c.get("/work-logs/templates", headers=h_chen)
    check("GET templates 裸数组", isinstance(r.json()["data"], list) and r.json()["data"][0]["is_default"] in (0, 1))
    r = c.get("/work-logs/tags", headers=h_chen)
    check("GET tags 裸数组", isinstance(r.json()["data"], list))
    # 热力图
    r = c.get("/work-logs/calendar-heatmap", headers=h_chen, params={"year": 2026, "month": 10})
    hm = r.json()["data"]
    check("heatmap 2026-10 返回 31 格 + status 枚举",
          r.status_code == 200 and len(hm) == 31
          and set(x["status"] for x in hm) <= {"rest", "submitted", "delayed", "future", "absent"})
    # 卡点
    r = c.get("/work-logs/blockers", headers=h_root)
    bk = r.json()["data"]
    check("GET blockers 裸数组且字段齐",
          isinstance(bk, list) and all(set(x) == {"log_id", "date", "blocker_text", "project_name", "author_name"} for x in bk))
    check("blockers 非空 (数据已复活)", len(bk) >= 1, f"count={len(bk)}")

    # ---------- 8. 复盘读 ----------
    print("\n== 复盘读 ==")
    r = c.get("/retrospectives", headers=h_root, params={"page_size": 50})
    rr = r.json()["data"]
    check("GET reports 返回 {items,total}", isinstance(rr, dict) and {"items", "total"} <= set(rr))
    if rr["items"]:
        rid = rr["items"][0]["id"]
        r2 = c.get(f"/retrospectives/{rid}", headers=h_root)
        det = r2.json()["data"]
        check("report 详情字段齐 (final_content/ai_draft/kiss/blocker_keywords)",
              {"final_content", "ai_draft", "kiss_structured_json", "blocker_keywords"} <= set(det))
        check("kiss 四象限键齐", set(det["kiss_structured_json"]) == {"keep", "improve", "start", "stop"})
    r = c.get("/retrospectives/action-items", headers=h_root)
    ai = r.json()["data"]
    check("GET action-items 裸数组 + 字段齐",
          isinstance(ai, list) and all({"id", "title", "deadline", "status", "assignee_name", "priority",
                                        "result_summary"} <= set(x) for x in ai))

    # ---------- 9. stats ----------
    print("\n== 效能度量 ==")
    r = c.get("/stats/overview", headers=h_root)
    ov = r.json()["data"]
    check("overview KPI 字段齐",
          {"team_name", "member_count", "submission_rate", "on_time_rate", "total_spent_hours",
           "active_blockers_count", "open_action_items_count"} <= set(ov))
    check("overview 数值类型正确", all(isinstance(ov[k], int) for k in
          ["member_count", "active_blockers_count", "open_action_items_count"])
          and isinstance(ov["total_spent_hours"], (int, float)))
    check("member_count=10 且 active_blockers>=1", ov["member_count"] == 10 and ov["active_blockers_count"] >= 1,
          f"member={ov['member_count']} blockers={ov['active_blockers_count']}")
    r = c.get("/stats/burn-down", headers=h_root, params={"days": 14})
    bd = r.json()["data"]
    check("burn-down 14 点 + 字段", len(bd) == 14 and all({"date", "spent_hours", "remaining_hours"} <= set(x) for x in bd)
          and is_d(bd[0]["date"]))
    r = c.get("/stats/radar", headers=h_root)
    rd = r.json()["data"]
    check("radar 五维结构", len(rd["indicators"]) == 5 and len(rd["current_values"]) == 5 and len(rd["team_avg_values"]) == 5)
    r = c.get("/stats/snapshots", headers=h_root, params={"limit": 10})
    sn = r.json()["data"]
    check("snapshots 裸数组 + 字段", isinstance(sn, list) and all(
          {"snapshot_date", "submission_rate", "total_spent_hours", "blocker_count"} <= set(x) for x in sn))

    # ---------- 10. AI ----------
    print("\n== AI 网关 ==")
    r = c.get("/ai/models", headers=h_root)
    md = r.json()["data"]
    check("GET /ai/models 裸数组", isinstance(md, list) and len(md) >= 1)
    check("ai models 无 api_key 泄漏", all("api_key" not in m for m in md))
    check("ai models 字段齐", all({"id", "provider_name", "model_identifier", "is_default", "is_active"} <= set(m) for m in md))
    r = c.get("/ai/call-logs", headers=h_root)
    check("root GET /ai/call-logs 200", r.status_code == 200 and isinstance(r.json()["data"], list))
    r = c.get("/ai/call-logs", headers=auth_header(tokens["dev_chen"]["access_token"]))
    check("MEMBER 查 Token 审计 -> 403", r.status_code == 403, str(r.status_code))
    # SSE
    with c.stream("POST", "/ai/stream", headers=auth_header(tokens["dev_zhou"]["access_token"]),
                  json={"prompt": "生成后端架构复盘"}) as r:
        sse = "".join(r.iter_text())
    check("SSE 流式返回 data: 与 [DONE]", r.status_code == 200 and "data:" in sse and "[DONE]" in sse)
    created["stream_user"] = tokens["dev_zhou"]["user"]["id"]

    # ---------- 11. 写操作 (带清洗) ----------
    print("\n== 写操作 ==")
    zh_zhang = auth_header(tokens["leader_zhang"]["access_token"])
    zh_li = auth_header(tokens["leader_li"]["access_token"])

    # 团队创建 (root) + 更新
    r = c.post("/teams", headers=h_root, json={"name": "ZZTEST临时组", "code": "ZZTEST"})
    check("root 创建团队 200", r.status_code == 200, str(r.text[:200]))
    tid = r.json()["data"]["id"]
    created["teams"].append(tid)
    r = c.put(f"/teams/{tid}", headers=h_root, json={"description": "updated"})
    check("root 更新团队 200", r.status_code == 200, str(r.text[:200]))

    # 项目创建 (leader 团队内) + 跨团队越权检测
    r = c.post("/projects", headers=zh_zhang, json={"name": "ZZTEST项目", "code": "ZZTESTP", "team_id": 1})
    check("leader 本团队建项目 200", r.status_code == 200, str(r.text[:200]))
    pid = r.json()["data"]["id"]
    created["projects"].append(pid)
    # 关键越权探测：leader_li(团队2) 给团队1建项目
    r = c.post("/projects", headers=zh_li, json={"name": "越权项目", "code": "ZZTESTX", "team_id": 1})
    cross_project_vuln = r.status_code == 200
    check("leader_li 跨团队建项目应被拒绝", not cross_project_vuln,
          f"status={r.status_code} (200=存在越权漏洞)")
    if cross_project_vuln:
        created["projects"].append(r.json()["data"]["id"])  # 清理越权产物

    # 日志 CRUD
    r = c.post("/work-logs", headers=zh_zhang, json={
        "template_id": 1, "project_id": pid, "log_date": "2026-10-20", "spent_hours": 7.5,
        "content_json": {"task": "ZZTEST 严格测试", "blockers": "Redis 主从切换抖动", "tomorrow_plan": "复测"},
        "tag_ids": [1, 2]})
    check("创建日志 200 {id,is_delayed,current_version}", r.status_code == 200
          and set(r.json()["data"]) == {"id", "is_delayed", "current_version"})
    lid = r.json()["data"]["id"]
    created["logs"].append(lid)
    r = c.get(f"/work-logs/{lid}", headers=zh_zhang)
    check("日志详情含 versions/comments", {"versions", "comments"} <= set(r.json()["data"]))
    r = c.put(f"/work-logs/{lid}", headers=zh_zhang, json={"spent_hours": 8.0, "content_json": {"task": "ZZTEST v2"}})
    check("更新日志 200", r.status_code == 200)
    r = c.post(f"/work-logs/{lid}/rollback", headers=zh_zhang, json={"target_version": 1, "reason": "回归"})
    check("回滚日志 200", r.status_code == 200)
    r = c.post(f"/work-logs/{lid}/comments", headers=zh_zhang, json={"content": "ZZTEST 批注", "score_rating": 4})
    check("批注 200", r.status_code == 200)
    r = c.post(f"/work-logs/{lid}/score", headers=zh_zhang, json={"score": 5})
    check("评星 200", r.status_code == 200)
    # 越权：leader_li(团队2) 不可评团队1的日志 (lid 属于团队1)
    r = c.post(f"/work-logs/{lid}/score", headers=zh_li, json={"score": 4})
    check("跨团队评星 -> 403", r.status_code == 403, str(r.status_code))
    # 评分越界 -> 422
    r = c.post(f"/work-logs/{lid}/score", headers=zh_zhang, json={"score": 9})
    check("评分越界 -> 422", r.status_code == 422, str(r.status_code))

    # 复盘报告 (leader) + 行动项更新
    r = c.post("/retrospectives", headers=zh_zhang, json={
        "title": "ZZTEST复盘报告", "template_id": 1, "start_date": "2026-10-01", "end_date": "2026-10-07", "scope_type": "TEAM"})
    check("创建复盘报告 200", r.status_code == 200, str(r.text[:300]))
    rpt_id = r.json()["data"]["id"]
    created["reports"].append(rpt_id)
    r = c.put(f"/retrospectives/{rpt_id}", headers=zh_zhang, json={"final_content": "ZZTEST 修订定稿"})
    check("更新复盘报告 200", r.status_code == 200)
    # 行动项 (取该团队任一行动项)
    r = c.get("/retrospectives/action-items", headers=zh_zhang)
    items = r.json()["data"]
    if items:
        it0 = items[0]
        r = c.put(f"/retrospectives/action-items/{it0['id']}", headers=zh_zhang,
                  json={"status": "DOING", "result_summary": "推进中"})
        check("更新行动项 200", r.status_code == 200)
    # 成员不可发起复盘
    r = c.post("/retrospectives", headers=auth_header(tokens["dev_chen"]["access_token"]),
               json={"title": "非法", "start_date": "2026-10-01", "end_date": "2026-10-07"})
    check("MEMBER 发起复盘 -> 403", r.status_code == 403, str(r.status_code))

    # ---------- 12. 422 校验抽样 ----------
    print("\n== 422 校验抽样 ==")
    r = c.post("/work-logs", headers=zh_zhang, json={"spent_hours": 99})  # 缺 log_date 且 spent>24
    check("非法日志体 -> 422", r.status_code == 422, str(r.status_code))
    r = c.get("/work-logs", headers=h_root, params={"page": 0})
    check("page=0 -> 422", r.status_code == 422, str(r.status_code))
    r = c.get("/stats/burn-down", headers=h_root, params={"days": 999})
    check("burn-down days>60 -> 422", r.status_code == 422, str(r.status_code))

    # ---------- 13. 未知路由 / openapi ----------
    print("\n== 其他 ==")
    r = c.get("/nope")
    check("未知路由 -> 404", r.status_code == 404, str(r.status_code))
    r = c.get("http://127.0.0.1:8000/api/openapi.json")
    check("openapi.json 可达", r.status_code == 200 and "/api/v1" in r.text)

    c.close()

    # ---------- 清洗测试数据 ----------
    print("\n== 清洗测试数据 ==")
    from app.core.database import AsyncSessionLocal
    from sqlalchemy import text
    import asyncio

    def _ids(xs):
        return ",".join(str(int(i)) for i in xs)

    async def _cleanup():
        async with AsyncSessionLocal() as s:
            if created["logs"]:
                await s.execute(text(f"DELETE FROM work_log_comments WHERE log_id IN ({_ids(created['logs'])})"))
                await s.execute(text(f"DELETE FROM work_log_versions WHERE log_id IN ({_ids(created['logs'])})"))
                await s.execute(text(f"DELETE FROM work_log_tag_rel WHERE log_id IN ({_ids(created['logs'])})"))
                await s.execute(text(f"DELETE FROM work_logs WHERE id IN ({_ids(created['logs'])})"))
            if created["reports"]:
                await s.execute(text(f"DELETE FROM llm_call_logs WHERE report_id IN ({_ids(created['reports'])})"))
                await s.execute(text(f"DELETE FROM retrospective_action_items WHERE report_id IN ({_ids(created['reports'])})"))
                await s.execute(text(f"DELETE FROM retrospective_reports WHERE id IN ({_ids(created['reports'])})"))
            if created["stream_user"]:
                await s.execute(text("DELETE FROM llm_call_logs WHERE report_id IS NULL AND user_id = :u"),
                                {"u": int(created["stream_user"])})
            if created["projects"]:
                await s.execute(text(f"DELETE FROM projects WHERE id IN ({_ids(created['projects'])})"))
            if created["teams"]:
                await s.execute(text(f"DELETE FROM teams WHERE id IN ({_ids(created['teams'])})"))
            await s.commit()

    asyncio.run(_cleanup())
    print("  [OK] 测试数据已清洗")

    print(f"\n===== 结果: {PASS} 通过 / {FAIL} 失败 =====")
    if FAILED:
        print("失败项:")
        for f in FAILED:
            print("  -", f)
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())