-- ====================================================================
-- 演示数据时间线前移脚本 (可选，一次性)
-- --------------------------------------------------------------------
-- 用途：schema_and_seeds.sql 的时间线锚定在 2026-09 月；若实际演示日期
-- 已晚于该时点，「近14天卡点看板 / 燃尽图 / 活跃卡点」等相对窗口会偏空。
-- 本脚本将除 work_calendars 外的所有 date/datetime 列统一 +18 天，
-- 使最近活动落在「昨天」附近，保证 BI 大屏首屏数据饱满。
--
-- 使用：先导入 schema_and_seeds.sql，再执行本脚本：
--   mysql -h127.0.0.1 -uroot -p --default-character-set=utf8mb4 < schema_and_seeds.sql
--   mysql -h127.0.0.1 -uroot -p --default-character-set=utf8mb4 < seed_date_shift.sql
--
-- 说明：work_calendars 为按日唯一的 9 月公休日历，保留不动 (其唯一键
-- uk_cal_date 会与 +18 偏移重叠)；work_logs 带 (user_id, log_date) 唯一键，
-- 需以 log_date DESC 顺序更新避免瞬时重复键。
-- ====================================================================

USE `end_design_db`;
SET @OFF = 18;

UPDATE ai_model_configs SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY), updated_at = DATE_ADD(updated_at, INTERVAL @OFF DAY);
UPDATE audit_logs SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY);
UPDATE daily_stat_snapshots SET snapshot_date = DATE_ADD(snapshot_date, INTERVAL @OFF DAY), created_at = DATE_ADD(created_at, INTERVAL @OFF DAY);
UPDATE llm_call_logs SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY);
UPDATE notifications SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY);
UPDATE password_histories SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY);
UPDATE project_members SET joined_at = DATE_ADD(joined_at, INTERVAL @OFF DAY);
UPDATE projects SET start_date = DATE_ADD(start_date, INTERVAL @OFF DAY), end_date = DATE_ADD(end_date, INTERVAL @OFF DAY), created_at = DATE_ADD(created_at, INTERVAL @OFF DAY), updated_at = DATE_ADD(updated_at, INTERVAL @OFF DAY);
UPDATE retrospective_action_items SET deadline = DATE_ADD(deadline, INTERVAL @OFF DAY), completed_at = DATE_ADD(completed_at, INTERVAL @OFF DAY), created_at = DATE_ADD(created_at, INTERVAL @OFF DAY), updated_at = DATE_ADD(updated_at, INTERVAL @OFF DAY);
UPDATE retrospective_reports SET start_date = DATE_ADD(start_date, INTERVAL @OFF DAY), end_date = DATE_ADD(end_date, INTERVAL @OFF DAY), created_at = DATE_ADD(created_at, INTERVAL @OFF DAY), updated_at = DATE_ADD(updated_at, INTERVAL @OFF DAY);
UPDATE retrospective_templates SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY);
UPDATE system_configs SET updated_at = DATE_ADD(updated_at, INTERVAL @OFF DAY);
UPDATE tags SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY);
UPDATE teams SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY), updated_at = DATE_ADD(updated_at, INTERVAL @OFF DAY);
UPDATE users SET locked_until = DATE_ADD(locked_until, INTERVAL @OFF DAY), password_changed_at = DATE_ADD(password_changed_at, INTERVAL @OFF DAY), created_at = DATE_ADD(created_at, INTERVAL @OFF DAY), updated_at = DATE_ADD(updated_at, INTERVAL @OFF DAY);
UPDATE work_log_attachments SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY);
UPDATE work_log_comments SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY);
UPDATE work_log_templates SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY), updated_at = DATE_ADD(updated_at, INTERVAL @OFF DAY);
UPDATE work_log_versions SET created_at = DATE_ADD(created_at, INTERVAL @OFF DAY);
-- work_logs：唯一键 (user_id, log_date)，降序更新规避瞬时重复
UPDATE work_logs SET log_date = DATE_ADD(log_date, INTERVAL @OFF DAY), created_at = DATE_ADD(created_at, INTERVAL @OFF DAY), updated_at = DATE_ADD(updated_at, INTERVAL @OFF DAY) ORDER BY log_date DESC;