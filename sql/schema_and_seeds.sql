-- ====================================================================
-- 团队工作日志与智能复盘管理系统 (Python FastAPI + Vue3)
-- 数据库完整建表与种子数据初始化脚本 (MySQL 8.0+)
-- 字符集：utf8mb4  排序规则：utf8mb4_unicode_ci
-- ====================================================================

CREATE DATABASE IF NOT EXISTS `end_design_db` 
  DEFAULT CHARACTER SET utf8mb4 
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `end_design_db`;

SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------------------------------------------------
-- 1. 团队组织表 (teams)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `teams`;
CREATE TABLE `teams` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '团队主键ID',
  `name` VARCHAR(64) NOT NULL COMMENT '团队名称 (如: 后端研发组)',
  `code` VARCHAR(32) NOT NULL COMMENT '团队唯一编码 (如: TEAM_BACKEND)',
  `leader_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '团队主管用户ID',
  `description` VARCHAR(255) DEFAULT NULL COMMENT '团队职责描述',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否正常启用 (1:启用, 0:停用)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_teams_code` (`code`),
  KEY `idx_teams_leader` (`leader_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='团队组织表';

-- --------------------------------------------------------------------
-- 2. 用户账号表 (users)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户主键ID',
  `team_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '归属团队ID (超管可为空)',
  `username` VARCHAR(64) NOT NULL COMMENT '登录账号名',
  `hashed_password` VARCHAR(255) NOT NULL COMMENT '加盐加密密码 (Argon2/BCrypt)',
  `real_name` VARCHAR(64) NOT NULL COMMENT '真实姓名',
  `email` VARCHAR(128) DEFAULT NULL COMMENT '邮箱',
  `phone` VARCHAR(32) DEFAULT NULL COMMENT '联系手机号',
  `avatar_url` VARCHAR(255) DEFAULT NULL COMMENT '头像地址',
  `role` ENUM('SUPER_ADMIN', 'TEAM_LEADER', 'MEMBER') NOT NULL DEFAULT 'MEMBER' COMMENT '三级角色: 超级管理员/团队主管/普通员工',
  `status` ENUM('PENDING_REVIEW', 'ACTIVE', 'DISABLED', 'LOCKED', 'PASSWORD_EXPIRED') NOT NULL DEFAULT 'PENDING_REVIEW' COMMENT '账号互斥状态机',
  `is_root` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否为Root超级特权账号 (1:豁免锁定与禁用)',
  `failed_login_attempts` INT NOT NULL DEFAULT 0 COMMENT '连续输错密码次数',
  `locked_until` DATETIME DEFAULT NULL COMMENT '密码锁定解除时间点',
  `password_changed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最后改密时间 (用于判断过期)',
  `wechat_userid` VARCHAR(64) DEFAULT NULL COMMENT '绑定的企业微信成员ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_username` (`username`),
  KEY `idx_users_team` (`team_id`),
  KEY `idx_users_status` (`status`),
  KEY `idx_users_role` (`role`),
  CONSTRAINT `fk_users_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户账号表';

ALTER TABLE `teams` 
  ADD CONSTRAINT `fk_teams_leader` FOREIGN KEY (`leader_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

-- --------------------------------------------------------------------
-- 3. 历史密码表 (password_histories - 防近3次重复)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `password_histories`;
CREATE TABLE `password_histories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `hashed_password` VARCHAR(255) NOT NULL COMMENT '历史密码加盐哈希',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
  PRIMARY KEY (`id`),
  KEY `idx_pwd_user` (`user_id`),
  CONSTRAINT `fk_pwd_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='密码历史记录表';

-- --------------------------------------------------------------------
-- 4. 企业项目表 (projects)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `projects`;
CREATE TABLE `projects` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '项目主键ID',
  `team_id` BIGINT UNSIGNED NOT NULL COMMENT '主责归属团队ID',
  `code` VARCHAR(32) NOT NULL COMMENT '项目编码',
  `name` VARCHAR(128) NOT NULL COMMENT '项目名称',
  `manager_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '项目负责人(PM)用户ID',
  `start_date` DATE DEFAULT NULL COMMENT '计划启动日期',
  `end_date` DATE DEFAULT NULL COMMENT '计划结项日期',
  `status` ENUM('PLANNING', 'IN_PROGRESS', 'SUSPENDED', 'COMPLETED') NOT NULL DEFAULT 'IN_PROGRESS' COMMENT '项目状态',
  `description` TEXT DEFAULT NULL COMMENT '项目背景与范围描述',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_projects_code` (`code`),
  KEY `idx_projects_team` (`team_id`),
  KEY `idx_projects_manager` (`manager_id`),
  CONSTRAINT `fk_projects_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_projects_manager` FOREIGN KEY (`manager_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='企业项目表';

-- --------------------------------------------------------------------
-- 5. 项目成员关联表 (project_members)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `project_members`;
CREATE TABLE `project_members` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `project_id` BIGINT UNSIGNED NOT NULL COMMENT '项目ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '参与成员用户ID',
  `project_role` VARCHAR(32) NOT NULL DEFAULT 'DEV' COMMENT '项目角色 (PM/DEV/QA/OPS)',
  `joined_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入项目时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_project_user` (`project_id`, `user_id`),
  KEY `idx_pm_user` (`user_id`),
  CONSTRAINT `fk_pm_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pm_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目成员关联表';

-- --------------------------------------------------------------------
-- 6. 节假日与工作日历排班表 (work_calendars)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `work_calendars`;
CREATE TABLE `work_calendars` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `calendar_date` DATE NOT NULL COMMENT '日历日期 (YYYY-MM-DD)',
  `is_workday` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否为工作日 (1:应出勤写日志, 0:休息不考核)',
  `day_type` ENUM('WORKDAY', 'WEEKEND', 'HOLIDAY', 'COMPENSATORY_WORKDAY') NOT NULL DEFAULT 'WORKDAY' COMMENT '类型',
  `note` VARCHAR(64) DEFAULT NULL COMMENT '节假日备注',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cal_date` (`calendar_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工作日历与节假日排班表';

-- --------------------------------------------------------------------
-- 7. 日志表单模板表 (work_log_templates)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `work_log_templates`;
CREATE TABLE `work_log_templates` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '模板主键ID',
  `team_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '归属团队ID (NULL为全公司通用)',
  `name` VARCHAR(64) NOT NULL COMMENT '模板名称',
  `code` VARCHAR(32) NOT NULL COMMENT '模板编码',
  `schema_json` JSON NOT NULL COMMENT '动态字段配置定义 (JSONSchema规范)',
  `is_default` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否默认',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_tpl_code` (`code`),
  KEY `idx_log_tpl_team` (`team_id`),
  CONSTRAINT `fk_log_tpl_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日志表单模板表';

-- --------------------------------------------------------------------
-- 8. 业务与技术标签表 (tags)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `tags`;
CREATE TABLE `tags` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '标签主键ID',
  `team_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '归属团队ID (NULL表示全公司公共标签)',
  `name` VARCHAR(32) NOT NULL COMMENT '标签名称',
  `color` VARCHAR(16) NOT NULL DEFAULT '#409EFF' COMMENT '前端渲染色彩HEX',
  `category` ENUM('TASK_TYPE', 'TECH_STACK', 'CUSTOM') NOT NULL DEFAULT 'TASK_TYPE' COMMENT '分类',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否可用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_tags_team` (`team_id`),
  CONSTRAINT `fk_tags_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='业务与技术标签表';

-- --------------------------------------------------------------------
-- 9. 工作日志主表 (work_logs)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `work_logs`;
CREATE TABLE `work_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志主键ID',
  `team_id` BIGINT UNSIGNED NOT NULL COMMENT '归属团队ID (行级数据隔离核心外键)',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '填报员工ID',
  `project_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '主要关联项目ID',
  `template_id` BIGINT UNSIGNED NOT NULL COMMENT '使用的填报模板ID',
  `log_date` DATE NOT NULL COMMENT '工作归属日期 (YYYY-MM-DD)',
  `content_json` JSON NOT NULL COMMENT '动态内容快照JSON',
  `spent_hours` DECIMAL(4,1) NOT NULL DEFAULT 8.0 COMMENT '实际消耗总工时',
  `is_delayed` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否为迟交/补交 (1:迟交, 0:准时提交)',
  `status` ENUM('NORMAL', 'ARCHIVED') NOT NULL DEFAULT 'NORMAL' COMMENT '状态',
  `current_version` INT NOT NULL DEFAULT 1 COMMENT '当前版本号',
  `score` TINYINT UNSIGNED DEFAULT NULL COMMENT '主管评分 (1~5星)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '提交时间戳',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间戳',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_date` (`user_id`, `log_date`),
  KEY `idx_logs_team_date` (`team_id`, `log_date`),
  KEY `idx_logs_project` (`project_id`),
  KEY `idx_logs_template` (`template_id`),
  KEY `idx_logs_delayed` (`is_delayed`),
  KEY `idx_logs_status` (`status`),
  CONSTRAINT `fk_logs_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_logs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_logs_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_logs_template` FOREIGN KEY (`template_id`) REFERENCES `work_log_templates` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工作日志主表';

-- --------------------------------------------------------------------
-- 10. 日志-标签多对多关联表 (work_log_tag_rel)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `work_log_tag_rel`;
CREATE TABLE `work_log_tag_rel` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `log_id` BIGINT UNSIGNED NOT NULL COMMENT '日志ID',
  `tag_id` BIGINT UNSIGNED NOT NULL COMMENT '标签ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_tag` (`log_id`, `tag_id`),
  KEY `idx_rel_tag` (`tag_id`),
  CONSTRAINT `fk_rel_log` FOREIGN KEY (`log_id`) REFERENCES `work_logs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rel_tag` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日志与标签关联表';

-- --------------------------------------------------------------------
-- 11. 日志历史版本快照表 (work_log_versions)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `work_log_versions`;
CREATE TABLE `work_log_versions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '快照主键ID',
  `log_id` BIGINT UNSIGNED NOT NULL COMMENT '归属日志ID',
  `version_num` INT NOT NULL COMMENT '版本快照序号',
  `operator_id` BIGINT UNSIGNED NOT NULL COMMENT '修改操作人ID',
  `content_json` JSON NOT NULL COMMENT '当时修改写入的完整JSON快照',
  `spent_hours` DECIMAL(4,1) NOT NULL COMMENT '当时的工时快照',
  `change_summary` VARCHAR(255) DEFAULT NULL COMMENT '修改备注',
  `is_rollback` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否为回滚生成',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '快照生成时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_version` (`log_id`, `version_num`),
  KEY `idx_ver_operator` (`operator_id`),
  CONSTRAINT `fk_ver_log` FOREIGN KEY (`log_id`) REFERENCES `work_logs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ver_operator` FOREIGN KEY (`operator_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日志历史版本快照表';

-- --------------------------------------------------------------------
-- 12. 日志附件表 (work_log_attachments)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `work_log_attachments`;
CREATE TABLE `work_log_attachments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '附件主键ID',
  `log_id` BIGINT UNSIGNED NOT NULL COMMENT '归属日志ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '上传人ID',
  `original_name` VARCHAR(255) NOT NULL COMMENT '用户原始文件名',
  `stored_name` VARCHAR(128) NOT NULL COMMENT '磁盘物理存储文件名(UUID)',
  `file_path` VARCHAR(512) NOT NULL COMMENT '服务器物理存储相对路径',
  `file_size` BIGINT UNSIGNED NOT NULL COMMENT '文件字节大小',
  `mime_type` VARCHAR(128) NOT NULL COMMENT '文件魔数MIME',
  `file_ext` VARCHAR(16) NOT NULL COMMENT '扩展名',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  PRIMARY KEY (`id`),
  KEY `idx_attach_log` (`log_id`),
  KEY `idx_attach_user` (`user_id`),
  CONSTRAINT `fk_attach_log` FOREIGN KEY (`log_id`) REFERENCES `work_logs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_attach_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日志附件表';

-- --------------------------------------------------------------------
-- 13. 日志双向一级评论表 (work_log_comments)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `work_log_comments`;
CREATE TABLE `work_log_comments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '评论主键ID',
  `log_id` BIGINT UNSIGNED NOT NULL COMMENT '归属日志ID',
  `author_id` BIGINT UNSIGNED NOT NULL COMMENT '发言人用户ID',
  `content` TEXT NOT NULL COMMENT '评论/批注文本内容',
  `score_rating` TINYINT UNSIGNED DEFAULT NULL COMMENT '伴随打分',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发表时间',
  PRIMARY KEY (`id`),
  KEY `idx_comment_log` (`log_id`),
  KEY `idx_comment_author` (`author_id`),
  CONSTRAINT `fk_comment_log` FOREIGN KEY (`log_id`) REFERENCES `work_logs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comment_author` FOREIGN KEY (`author_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日志双向一级评论表';

-- --------------------------------------------------------------------
-- 14. AI 模型网关配置表 (ai_model_configs)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `ai_model_configs`;
CREATE TABLE `ai_model_configs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '模型配置ID',
  `provider_name` VARCHAR(32) NOT NULL COMMENT '供应商',
  `model_identifier` VARCHAR(64) NOT NULL COMMENT '模型标识串',
  `api_base_url` VARCHAR(255) NOT NULL COMMENT 'API代理基础地址',
  `api_key` VARCHAR(255) NOT NULL COMMENT 'API密钥',
  `context_window` INT NOT NULL DEFAULT 32768 COMMENT '上下文Token窗口上限',
  `max_tokens` INT NOT NULL DEFAULT 4096 COMMENT '单次最大生成Token数',
  `temperature` DECIMAL(2,1) NOT NULL DEFAULT 0.7 COMMENT '采样温度',
  `is_default` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否为主力默认模型',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_provider_model` (`provider_name`, `model_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI模型网关配置表';

-- --------------------------------------------------------------------
-- 15. 复盘方法论模板表 (retrospective_templates)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `retrospective_templates`;
CREATE TABLE `retrospective_templates` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '模板主键ID',
  `name` VARCHAR(64) NOT NULL COMMENT '模板名称',
  `model_framework` ENUM('KISS', 'GRAI', 'ORID', 'CUSTOM') NOT NULL DEFAULT 'KISS' COMMENT '方法论体系',
  `prompt_system` TEXT NOT NULL COMMENT '系统指导Prompt',
  `prompt_template` TEXT NOT NULL COMMENT '模板Prompt',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='复盘方法论模板表';

-- --------------------------------------------------------------------
-- 16. 智能复盘报告表 (retrospective_reports)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `retrospective_reports`;
CREATE TABLE `retrospective_reports` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '报告主键ID',
  `team_id` BIGINT UNSIGNED NOT NULL COMMENT '归属团队ID',
  `creator_id` BIGINT UNSIGNED NOT NULL COMMENT '发起人用户ID',
  `template_id` BIGINT UNSIGNED NOT NULL COMMENT '套用的复盘模板ID',
  `ai_model_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '调用的AI模型ID',
  `title` VARCHAR(128) NOT NULL COMMENT '复盘报告标题',
  `scope_type` ENUM('TEAM', 'PERSONAL') NOT NULL DEFAULT 'TEAM' COMMENT '范围',
  `start_date` DATE NOT NULL COMMENT '起始日期',
  `end_date` DATE NOT NULL COMMENT '截止日期',
  `ai_draft` MEDIUMTEXT DEFAULT NULL COMMENT 'AI生成的原始初稿',
  `final_content` MEDIUMTEXT DEFAULT NULL COMMENT '人工润色后的最终定稿',
  `kiss_structured_json` JSON DEFAULT NULL COMMENT '结构化KISS JSON',
  `blocker_keywords` JSON DEFAULT NULL COMMENT 'Top高频卡点词频列表',
  `status` ENUM('QUEUED', 'PROCESSING', 'SUCCESS', 'FAILED') NOT NULL DEFAULT 'QUEUED' COMMENT '状态机',
  `error_message` VARCHAR(512) DEFAULT NULL COMMENT '失败原因',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_retro_team_date` (`team_id`, `start_date`, `end_date`),
  KEY `idx_retro_creator` (`creator_id`),
  KEY `idx_retro_template` (`template_id`),
  KEY `idx_retro_status` (`status`),
  CONSTRAINT `fk_retro_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_retro_creator` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_retro_template` FOREIGN KEY (`template_id`) REFERENCES `retrospective_templates` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_retro_aimodel` FOREIGN KEY (`ai_model_id`) REFERENCES `ai_model_configs` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='智能复盘报告表';

-- --------------------------------------------------------------------
-- 17. 复盘行动项闭环表 (retrospective_action_items)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `retrospective_action_items`;
CREATE TABLE `retrospective_action_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '行动项主键ID',
  `report_id` BIGINT UNSIGNED NOT NULL COMMENT '来源复盘报告ID',
  `team_id` BIGINT UNSIGNED NOT NULL COMMENT '归属团队ID',
  `assignee_id` BIGINT UNSIGNED NOT NULL COMMENT '被指派责任人用户ID',
  `title` VARCHAR(128) NOT NULL COMMENT '改进事项名称',
  `description` TEXT DEFAULT NULL COMMENT '具体措施与标准',
  `deadline` DATE NOT NULL COMMENT '截止日期',
  `status` ENUM('TODO', 'DOING', 'DONE', 'OVERDUE') NOT NULL DEFAULT 'TODO' COMMENT '执行状态机',
  `result_summary` TEXT DEFAULT NULL COMMENT '完成成果凭据说明',
  `completed_at` DATETIME DEFAULT NULL COMMENT '实际完成时间',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_act_report` (`report_id`),
  KEY `idx_act_team_status` (`team_id`, `status`),
  KEY `idx_act_assignee` (`assignee_id`),
  CONSTRAINT `fk_act_report` FOREIGN KEY (`report_id`) REFERENCES `retrospective_reports` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_act_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_act_assignee` FOREIGN KEY (`assignee_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='复盘行动项闭环表';

-- --------------------------------------------------------------------
-- 18. LLM 调用与 Token 审计表 (llm_call_logs)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `llm_call_logs`;
CREATE TABLE `llm_call_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '调用主键ID',
  `ai_model_id` BIGINT UNSIGNED NOT NULL COMMENT '模型配置ID',
  `report_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '复盘任务ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '触发用户ID',
  `prompt_tokens` INT NOT NULL DEFAULT 0 COMMENT '输入Token数',
  `completion_tokens` INT NOT NULL DEFAULT 0 COMMENT '输出Token数',
  `total_tokens` INT NOT NULL DEFAULT 0 COMMENT '总Token开销',
  `latency_ms` INT NOT NULL DEFAULT 0 COMMENT '耗时(ms)',
  `call_status` ENUM('SUCCESS', 'FAILED') NOT NULL DEFAULT 'SUCCESS' COMMENT '状态',
  `error_info` TEXT DEFAULT NULL COMMENT '错误摘要',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '调用时间',
  PRIMARY KEY (`id`),
  KEY `idx_llm_model` (`ai_model_id`),
  KEY `idx_llm_report` (`report_id`),
  KEY `idx_llm_user` (`user_id`),
  CONSTRAINT `fk_llm_model` FOREIGN KEY (`ai_model_id`) REFERENCES `ai_model_configs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_llm_report` FOREIGN KEY (`report_id`) REFERENCES `retrospective_reports` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_llm_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='LLM调用与Token审计表';

-- --------------------------------------------------------------------
-- 19. 每日效能聚合快照表 (daily_stat_snapshots - 秒开大屏支撑)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `daily_stat_snapshots`;
CREATE TABLE `daily_stat_snapshots` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `snapshot_date` DATE NOT NULL COMMENT '统计日期 (YYYY-MM-DD)',
  `team_id` BIGINT UNSIGNED NOT NULL COMMENT '归属团队ID',
  `expected_count` INT NOT NULL DEFAULT 0 COMMENT '当日应交日志人数',
  `actual_count` INT NOT NULL DEFAULT 0 COMMENT '当日实际提交人数',
  `on_time_count` INT NOT NULL DEFAULT 0 COMMENT '按时提交人数',
  `delayed_count` INT NOT NULL DEFAULT 0 COMMENT '迟交/补交人数',
  `submission_rate` DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT '按时提交合规率 (%)',
  `total_spent_hours` DECIMAL(6,1) NOT NULL DEFAULT 0.0 COMMENT '当日总工时',
  `project_hours_json` JSON DEFAULT NULL COMMENT '各项目工时分布快照',
  `blocker_count` INT NOT NULL DEFAULT 0 COMMENT '当日问题卡点总数',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '快照生成时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_snap_team_date` (`team_id`, `snapshot_date`),
  KEY `idx_snap_date` (`snapshot_date`),
  CONSTRAINT `fk_snap_team` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='每日效能聚合快照表';

-- --------------------------------------------------------------------
-- 20. 系统全局配置表 (system_configs)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `system_configs`;
CREATE TABLE `system_configs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '配置主键ID',
  `config_key` VARCHAR(64) NOT NULL COMMENT '唯一配置键',
  `config_value` TEXT NOT NULL COMMENT '配置值',
  `description` VARCHAR(255) DEFAULT NULL COMMENT '描述',
  `is_secret` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否敏感',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统全局参数配置表';

-- --------------------------------------------------------------------
-- 21. 双渠道通知中心表 (notifications)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '通知主键ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '接收用户ID',
  `team_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '事件团队ID',
  `title` VARCHAR(128) NOT NULL COMMENT '通知标题',
  `content` TEXT NOT NULL COMMENT '通知内容',
  `notify_type` ENUM('REMINDER', 'ALERT', 'COMMENT', 'RETROSPECTIVE', 'SYSTEM') NOT NULL DEFAULT 'SYSTEM' COMMENT '分类',
  `is_read` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否已读',
  `channel` ENUM('STATION', 'WECHAT', 'ALL') NOT NULL DEFAULT 'ALL' COMMENT '渠道',
  `wechat_send_status` ENUM('PENDING', 'SENT', 'FAILED', 'SANDBOX') NOT NULL DEFAULT 'PENDING' COMMENT '企微状态',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  PRIMARY KEY (`id`),
  KEY `idx_notify_user_read` (`user_id`, `is_read`),
  KEY `idx_notify_team` (`team_id`),
  CONSTRAINT `fk_notify_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='双渠道通知中心表';

-- --------------------------------------------------------------------
-- 22. 全局不可篡改安全审计日志表 (audit_logs)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '审计主键ID',
  `team_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '所属团队ID',
  `operator_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '操作人ID',
  `operator_name` VARCHAR(64) NOT NULL COMMENT '操作人姓名快照',
  `action_type` VARCHAR(64) NOT NULL COMMENT '动作类型',
  `resource_target` VARCHAR(128) NOT NULL COMMENT '操作受体',
  `ip_address` VARCHAR(64) DEFAULT NULL COMMENT '客户端IP',
  `user_agent` VARCHAR(255) DEFAULT NULL COMMENT '浏览器UA',
  `status` ENUM('SUCCESS', 'FAILED') NOT NULL DEFAULT 'SUCCESS' COMMENT '执行结果',
  `extra_json` JSON DEFAULT NULL COMMENT '详情JSON',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_audit_team_date` (`team_id`, `created_at`),
  KEY `idx_audit_operator` (`operator_id`),
  KEY `idx_audit_action` (`action_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='全局不可篡改安全审计日志表';

SET FOREIGN_KEY_CHECKS = 1;


-- ====================================================================
-- 企业级正式生产业务数据初始化 (Seed Data - 100% UTF-8)
-- ====================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- teams 表正式数据 (5 条)
INSERT INTO teams (id, name, code, leader_id, description, is_active, created_at, updated_at) VALUES
(1, '后端架构研发组', 'TEAM_BACKEND', 2, '负责分布式支付清算中台、微服务治理与高可用技术底座研发', 1, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(2, '前端与跨端应用组', 'TEAM_FRONTEND', 3, '负责企业协同工作台Web端、Vue3水墨组件库及响应式跨端用户界面研发', 1, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(3, '测试与质量保障组', 'TEAM_QA', 4, '负责全流程自动化测试套件、全链路高并发压测平台与交付质量度量', 1, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(4, '数据智能与AI中台组', 'TEAM_AI', 9, '负责企业大模型统一智能网关、Prompt微调工程及KISS/GRAI复盘算法引擎研发', 1, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(5, '运维与云原生工程组', 'TEAM_DEVOPS', 11, '负责容器化集群编排、K8s高可用架构、CI/CD持续交付流水线与全景链路监控', 1, '2026-09-20 10:40:11', '2026-09-20 10:40:11');

-- users 表正式数据 (11 条)
INSERT INTO users (id, team_id, username, hashed_password, real_name, email, phone, avatar_url, role, status, is_root, failed_login_attempts, locked_until, password_changed_at, wechat_userid, created_at, updated_at) VALUES
(1, NULL, 'root', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '系统超级管理员', 'admin@enterprise.com', '13800000000', NULL, 'SUPER_ADMIN', 'ACTIVE', 1, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(2, 1, 'leader_zhang', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '张建国 (后端架构师)', 'zhang@enterprise.com', '13800138001', NULL, 'TEAM_LEADER', 'ACTIVE', 0, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(3, 2, 'leader_li', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '李晓华 (前端技术主管)', 'li@enterprise.com', '13800138002', NULL, 'TEAM_LEADER', 'ACTIVE', 0, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(4, 3, 'leader_wang', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '王海涛 (质量保障主管)', 'wang@enterprise.com', '13800138003', NULL, 'TEAM_LEADER', 'ACTIVE', 0, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(5, 1, 'dev_chen', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '陈明 (资深后端工程师)', 'chen@enterprise.com', '13800138005', NULL, 'MEMBER', 'ACTIVE', 0, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(6, 1, 'dev_zhao', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '赵云 (分布式存储工程师)', 'zhao@enterprise.com', '13800138006', NULL, 'MEMBER', 'ACTIVE', 0, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(7, 2, 'dev_liu', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '刘洋 (Web前端工程师)', 'liu@enterprise.com', '13800138007', NULL, 'MEMBER', 'ACTIVE', 0, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(8, 3, 'qa_sun', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '孙悦 (性能测试工程师)', 'sun@enterprise.com', '13800138008', NULL, 'MEMBER', 'ACTIVE', 0, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(9, 4, 'leader_qian', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '钱学森 (AI算法主管)', 'qian@enterprise.com', '13800138009', NULL, 'TEAM_LEADER', 'ACTIVE', 0, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(10, 4, 'dev_zhou', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '周杰 (大模型应用工程师)', 'zhou@enterprise.com', '13800138010', NULL, 'MEMBER', 'ACTIVE', 0, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(11, 5, 'leader_sun', '$2b$12$.CH34z7guclTg0SLtR5tzO5l0AtUNNQMNNXXvGbjKUU1y9U2bQ1jO', '孙浩然 (云原生运维主管)', 'haoran@enterprise.com', '13800138011', NULL, 'TEAM_LEADER', 'ACTIVE', 0, 0, NULL, '2026-09-20 10:40:11', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11');

-- projects 表正式数据 (5 条)
INSERT INTO projects (id, team_id, code, name, manager_id, start_date, end_date, status, description, created_at, updated_at) VALUES
(1, 1, 'PROJ_PAY', '企业统一支付清结算中台', 2, '2026-08-01', '2026-11-30', 'IN_PROGRESS', '接入微信、支付宝、银联跨行渠道的分布式高可用清结算与对账中台', '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(2, 2, 'PROJ_PORTAL', '企业一体化协同工作台V3.0', 3, '2026-08-15', '2026-12-31', 'IN_PROGRESS', '基于Vue3、Pinia与墨韵风格构建的企业内部统一门户与日常办公协作系统', '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(3, 3, 'PROJ_AUTO_TEST', '端到端全链路压测与质量度量平台', 4, '2026-09-01', '2026-10-31', 'IN_PROGRESS', '面向大促场景的高并发分布式全链路压测、故障注入与质量自动化断言平台', '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(4, 4, 'PROJ_LLM_GATEWAY', '企业级大模型统一智能网关', 9, '2026-08-20', '2026-12-20', 'IN_PROGRESS', '支持DeepSeek、Qwen等多模型动态路由、SSE流式打字机响应与Token配额管控中枢', '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(5, 5, 'PROJ_DEVOPS_OPS', '云原生持续交付与全景链路监控体系', 11, '2026-08-01', '2026-12-15', 'IN_PROGRESS', '基于Kubernetes与Prometheus的容器化自动弹性伸缩与调用链追踪工程', '2026-09-20 10:40:11', '2026-09-20 10:40:11');

-- project_members 表正式数据 (16 条)
INSERT INTO project_members (id, project_id, user_id, project_role, joined_at) VALUES
(1, 1, 2, 'PM', '2026-09-20 10:40:11'),
(2, 1, 5, 'DEV', '2026-09-20 10:40:11'),
(3, 1, 6, 'DEV', '2026-09-20 10:40:11'),
(4, 1, 8, 'QA', '2026-09-20 10:40:11'),
(5, 2, 3, 'PM', '2026-09-20 10:40:11'),
(6, 2, 7, 'DEV', '2026-09-20 10:40:11'),
(7, 2, 5, 'DEV_BACKEND_SUPPORT', '2026-09-20 10:40:11'),
(8, 3, 4, 'PM', '2026-09-20 10:40:11'),
(9, 3, 8, 'QA', '2026-09-20 10:40:11'),
(10, 3, 6, 'DEV', '2026-09-20 10:40:11'),
(11, 4, 9, 'PM', '2026-09-20 10:40:11'),
(12, 4, 10, 'DEV', '2026-09-20 10:40:11'),
(13, 4, 5, 'DEV', '2026-09-20 10:40:11'),
(14, 5, 11, 'PM', '2026-09-20 10:40:11'),
(15, 5, 6, 'DEV', '2026-09-20 10:40:11'),
(16, 5, 10, 'DEV', '2026-09-20 10:40:11');

-- work_log_templates 表正式数据 (2 条)
INSERT INTO work_log_templates (id, team_id, name, code, schema_json, is_default, is_active, created_at, updated_at) VALUES
(1, NULL, '通用标准日志模板', 'TPL_STANDARD', '{"fields": [{"key": "today_completed", "type": "textarea", "label": "今日工作产出", "required": true, "placeholder": "请条理分明列出今日核心交付物与代码产出"}, {"key": "blockers", "type": "textarea", "label": "遇到问题与阻碍点 (Blocker)", "required": false, "placeholder": "如遇外部依赖阻塞或技术卡点请说明，将汇入攻坚看板"}, {"key": "tomorrow_plan", "type": "textarea", "label": "明日工作计划", "required": true, "placeholder": "列出明日重点攻坚任务与排班"}]}', 1, 1, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(2, 1, '研发攻坚专用模板', 'TPL_DEV_DETAIL', '{"fields": [{"key": "today_completed", "type": "textarea", "label": "功能研发与代码提交", "required": true, "placeholder": "模块开发、重构或 Bug 修复详情"}, {"key": "code_review_notes", "type": "input", "label": "Code Review 评审要点", "required": false, "placeholder": "同行评审关注点与改进点"}, {"key": "blockers", "type": "textarea", "label": "技术卡点/联调阻塞", "required": false, "placeholder": "技术难题与外部协调项"}, {"key": "tomorrow_plan", "type": "textarea", "label": "明日重构/提测计划", "required": true, "placeholder": "下一步交付节点"}]}', 0, 1, '2026-09-20 10:40:11', '2026-09-20 10:40:11');

-- tags 表正式数据 (10 条)
INSERT INTO tags (id, team_id, name, color, category, is_active, created_at) VALUES
(1, NULL, '需求开发', '#409EFF', 'TASK_TYPE', 1, '2026-09-20 10:40:11'),
(2, NULL, 'Bug修复', '#F56C6C', 'TASK_TYPE', 1, '2026-09-20 10:40:11'),
(3, NULL, '架构重构', '#E6A23C', 'TASK_TYPE', 1, '2026-09-20 10:40:11'),
(4, NULL, 'CodeReview', '#67C23A', 'TASK_TYPE', 1, '2026-09-20 10:40:11'),
(5, 1, 'MySQL优化', '#909399', 'TECH_STACK', 1, '2026-09-20 10:40:11'),
(6, 1, 'Redis缓存', '#F56C6C', 'TECH_STACK', 1, '2026-09-20 10:40:11'),
(7, 2, 'Vue3组件化', '#42B883', 'TECH_STACK', 1, '2026-09-20 10:40:11'),
(8, 4, 'AI提示词工程', '#9B59B6', 'TECH_STACK', 1, '2026-09-20 10:40:11'),
(9, 3, '全链路压测', '#3498DB', 'TECH_STACK', 1, '2026-09-20 10:40:11'),
(10, 1, '微服务治理', '#1ABC9C', 'TECH_STACK', 1, '2026-09-20 10:40:11');

-- work_logs 表正式数据 (19 条)
INSERT INTO work_logs (id, team_id, user_id, project_id, template_id, log_date, content_json, spent_hours, is_delayed, status, current_version, score, created_at, updated_at) VALUES
(1, 1, 5, 1, 1, '2026-09-01', '{"task": "完成企业支付中台银联跨行清分批处理任务分片重构，编写分布式定时调度任务，优化 MySQL 慢查询索引，耗时从 4.2s 降至 85ms。", "blockers": "跨行对账批量拉取接口在大并发下偶发网络抖动超时，已增加重试退避机制。", "tomorrow_plan": "推进支付宝与微信渠道的统一支付流水幂等性校验模块编写。", "today_completed": "完成企业支付中台银联跨行清分批处理任务分片重构，编写分布式定时调度任务，优化 MySQL 慢查询索引，耗时从 4.2s 降至 85ms。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-01 18:15:00', '2026-09-01 18:15:00'),
(2, 1, 6, 1, 1, '2026-09-01', '{"task": "完成交易分库分表 Sharding 分片键设计与数据字典规范拟定，搭建 Canal 监听 MySQL binlog 实现异构数据同步。", "blockers": "Canal 在大事务下存在 300ms 复制延迟，正排查写入阻塞点。", "tomorrow_plan": "编写交易流水冷热数据分离归档脚本，预计降低主库 40% 存储压力。", "today_completed": "完成交易分库分表 Sharding 分片键设计与数据字典规范拟定，搭建 Canal 监听 MySQL binlog 实现异构数据同步。"}', 8.0, 0, 'NORMAL', 1, 4, '2026-09-01 18:15:00', '2026-09-01 18:15:00'),
(3, 2, 7, 2, 1, '2026-09-01', '{"task": "完成协同工作台整体水墨国风组件库视觉框架搭建，基于纯 CSS 实现墨韵宣纸质感卡片与自适应栅格系统，完全剔除外部 CDN 依赖。", "blockers": "", "tomorrow_plan": "封装基于 Pinia 的用户多角色与权限路由守卫动态生成逻辑。", "today_completed": "完成协同工作台整体水墨国风组件库视觉框架搭建，基于纯 CSS 实现墨韵宣纸质感卡片与自适应栅格系统，完全剔除外部 CDN 依赖。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-01 18:15:00', '2026-09-01 18:15:00'),
(4, 3, 8, 3, 1, '2026-09-02', '{"task": "编写 Locust 分布式全链路高并发压测脚本，对清结算 API 进行阶梯式增压测试，定位到连接池耗尽瓶颈。", "blockers": "压测过程中发现后端 asyncmy 数据库连接池满载抛出超时，需协同后端调优池上限。", "tomorrow_plan": "协助后端工程师验证连接池参数调优后的 3000 QPS 稳定运行指标。", "today_completed": "编写 Locust 分布式全链路高并发压测脚本，对清结算 API 进行阶梯式增压测试，定位到连接池耗尽瓶颈。"}', 8.0, 0, 'NORMAL', 1, 4, '2026-09-02 18:15:00', '2026-09-02 18:15:00'),
(5, 1, 5, 1, 2, '2026-09-02', '{"task": "重构支付网关接入层，引入基于 Redis 令牌桶算法的防刷限流中间件，完成基于 BCrypt 加盐鉴权的安全审计拦截。", "blockers": "测试环境发现 Redis 集群在主从切换瞬间存在短暂连接中断，已配置 pool_pre_ping 保活机制。", "tomorrow_plan": "优化订单结算事务边界，拆解长事务为两阶段轻量操作，减少行锁持有时间。", "today_completed": "重构支付网关接入层，引入基于 Redis 令牌桶算法的防刷限流中间件，完成基于 BCrypt 加盐鉴权的安全审计拦截。"}', 8.5, 0, 'NORMAL', 1, 5, '2026-09-02 18:15:00', '2026-09-02 18:15:00'),
(6, 2, 7, 2, 1, '2026-09-03', '{"task": "实现前端工作日志管理（笔部）工作台布局，完成卡点三关看板（待排查/攻坚中/已闭环）拖拽交互与状态更新。", "blockers": "ECharts 工时热力图日历组件在移动端响应式布局时存在图表重绘抖动，已通过 ResizeObserver 防抖修复。", "tomorrow_plan": "完成复盘驾驶舱四扇屏风（KISS 四象限）组件的响应式布局封装。", "today_completed": "实现前端工作日志管理（笔部）工作台布局，完成卡点三关看板（待排查/攻坚中/已闭环）拖拽交互与状态更新。"}', 7.5, 0, 'NORMAL', 1, 4, '2026-09-03 18:15:00', '2026-09-03 18:15:00'),
(7, 4, 10, 4, 1, '2026-09-03', '{"task": "完成大模型统一智能网关适配层搭建，统一封装 OpenAI、DeepSeek 与 Qwen 的流式通信接口，支持 SSE 打字机流式输出。", "blockers": "外部大模型 API 在高峰期可能出现限流或响应超时，设计了基于本地高仿真沙箱的无缝自动降级兜底方案。", "tomorrow_plan": "编写提示词模板动态注入引擎，支持根据团队多维日志自动构建 KISS 结构化 Prompt。", "today_completed": "完成大模型统一智能网关适配层搭建，统一封装 OpenAI、DeepSeek 与 Qwen 的流式通信接口，支持 SSE 打字机流式输出。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-03 18:15:00', '2026-09-03 18:15:00'),
(8, 1, 5, 1, 1, '2026-09-04', '{"task": "完成工作日志历史版本时光机追溯与版本回滚 API 开发，利用 MySQL 原生 JSON 字段存储完整内容快照与工时演进记录。", "blockers": "", "tomorrow_plan": "协助前端联调时光机抽屉界面与版本差异对比功能。", "today_completed": "完成工作日志历史版本时光机追溯与版本回滚 API 开发，利用 MySQL 原生 JSON 字段存储完整内容快照与工时演进记录。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-04 18:15:00', '2026-09-04 18:15:00'),
(9, 1, 6, 1, 1, '2026-09-07', '{"task": "完成分布式事务 Seata AT 模式接入测试，针对支付结算中扣减余额与生成流水跨库场景进行幂等防重保障。", "blockers": "分支事务在网络分区时偶发全局锁冲突，调整事务重试间隔与隔离级别。", "tomorrow_plan": "编写支付中心异常交易自动对账与告警补偿作业。", "today_completed": "完成分布式事务 Seata AT 模式接入测试，针对支付结算中扣减余额与生成流水跨库场景进行幂等防重保障。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-07 18:15:00', '2026-09-07 18:15:00'),
(10, 2, 7, 2, 1, '2026-09-08', '{"task": "实现复盘决议改进事项（Action Items）军令状看板与完成凭据上报弹窗，集成全局统一中文友好通知反馈。", "blockers": "部分表单输入框在极速回车提交时存在防抖失效重复触发，已添加按钮 loading 与防重复提交指令。", "tomorrow_plan": "联调墨部研发效能度量大屏，接入工时燃尽折线图与五维能力雷达图。", "today_completed": "实现复盘决议改进事项（Action Items）军令状看板与完成凭据上报弹窗，集成全局统一中文友好通知反馈。"}', 8.0, 0, 'NORMAL', 1, 4, '2026-09-08 18:15:00', '2026-09-08 18:15:00'),
(11, 3, 8, 3, 1, '2026-09-09', '{"task": "执行企业门户与支付中台跨团队集成回归测试用例 240 项，自动化通过率 98.3%，发现并闭环缺陷 4 处。", "blockers": "发现日志附件上传在校验魔数时对大文件耗时较长，建议后端引入分片嗅探机制。", "tomorrow_plan": "编写安全渗透测试报告，验证防 SQL 注入与防横向越权行级过滤。", "today_completed": "执行企业门户与支付中台跨团队集成回归测试用例 240 项，自动化通过率 98.3%，发现并闭环缺陷 4 处。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-09 18:15:00', '2026-09-09 18:15:00'),
(12, 1, 5, 1, 1, '2026-09-10', '{"task": "排查并修复异步数据库引擎连接泄漏问题，完善 SQLAlchemy 2.0 上下文管理器，确保每次请求精准关闭连接。", "blockers": "早期未配置 pool_recycle 导致 MySQL 8 小时空闲超时断连，现已在 config.py 统一注入保活参数。", "tomorrow_plan": "配合团队主管筹备 9 月上旬系统架构演进 KISS 复盘汇报数据准备。", "today_completed": "排查并修复异步数据库引擎连接泄漏问题，完善 SQLAlchemy 2.0 上下文管理器，确保每次请求精准关闭连接。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-10 18:15:00', '2026-09-10 18:15:00'),
(13, 2, 7, 2, 1, '2026-09-11', '{"task": "优化前端生产构建配置，引入 Rollup manualChunks 进行动态分包，将 vendor.js 体积从 1.2MB 优化至 420kB，首屏秒开率提升 65%。", "blockers": "", "tomorrow_plan": "整理前端 UI 设计规范与视觉风格指南文档，统一全平台设计规范。", "today_completed": "优化前端生产构建配置，引入 Rollup manualChunks 进行动态分包，将 vendor.js 体积从 1.2MB 优化至 420kB，首屏秒开率提升 65%。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-11 18:15:00', '2026-09-11 18:15:00'),
(14, 4, 10, 4, 1, '2026-09-14', '{"task": "完成智能复盘引擎中的结晶算法优化，采用 jieba 结巴分词与 TF-IDF 权重提取团队全员日志中的高频卡点词，按严重度自动聚类。", "blockers": "部分通用词（如\'完成\'、\'修复\'）需要停用词过滤字典过滤，已配置专用企业技术停用词表。", "tomorrow_plan": "支持一键下发复盘改进项（Action Items）至责任人并自动发送企业微信通知。", "today_completed": "完成智能复盘引擎中的结晶算法优化，采用 jieba 结巴分词与 TF-IDF 权重提取团队全员日志中的高频卡点词，按严重度自动聚类。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-14 18:15:00', '2026-09-14 18:15:00'),
(15, 1, 5, 1, 1, '2026-09-15', '{"task": "完成清结算中台与微信支付 V3 接口对账自动化流水生成，支持按批次导出格式化公文级 Word 复盘报告与对账单据。", "blockers": "", "tomorrow_plan": "完善主管日志审阅一键评星与快捷富文本批注后端接口。", "today_completed": "完成清结算中台与微信支付 V3 接口对账自动化流水生成，支持按批次导出格式化公文级 Word 复盘报告与对账单据。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-15 18:15:00', '2026-09-15 18:15:00'),
(16, 1, 6, 1, 1, '2026-09-16', '{"task": "完成生产级只读从库读写分离路由适配，在高并发报表统计与效能大屏查询时自动切入从库，保护主库核心交易事务。", "blockers": "主从数据同步在网络压力骤增时存在微秒级延迟，在强一致性查询时已配置强制路由主库注解。", "tomorrow_plan": "编写数据库表定期归档与冷备份自动化 shell 脚本。", "today_completed": "完成生产级只读从库读写分离路由适配，在高并发报表统计与效能大屏查询时自动切入从库，保护主库核心交易事务。"}', 8.0, 0, 'NORMAL', 1, 4, '2026-09-16 18:15:00', '2026-09-16 18:15:00'),
(17, 2, 7, 2, 1, '2026-09-17', '{"task": "完成系统墨部研发效能全景大屏的秒开优化，接入后端每日定时快照预计算数据，规避了全表扫描与复杂聚合查询。", "blockers": "", "tomorrow_plan": "配合各组主管进行多团队数据行级权限隔离验收。", "today_completed": "完成系统墨部研发效能全景大屏的秒开优化，接入后端每日定时快照预计算数据，规避了全表扫描与复杂聚合查询。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-17 18:15:00', '2026-09-17 18:15:00'),
(18, 3, 8, 3, 1, '2026-09-18', '{"task": "完成 5000 QPS 高负载全链路压测第二轮验收，系统平均响应时间维持在 32ms，P99 时延 < 85ms，CPU 与内存利用率平稳保持在 60% 以下。", "blockers": "", "tomorrow_plan": "输出《端到端全链路性能压测与架构高可用达标报告》。", "today_completed": "完成 5000 QPS 高负载全链路压测第二轮验收，系统平均响应时间维持在 32ms，P99 时延 < 85ms，CPU 与内存利用率平稳保持在 60% 以下。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-18 18:15:00', '2026-09-18 18:15:00'),
(19, 1, 5, 1, 1, '2026-09-19', '{"task": "配合团队主管完成本阶段研发任务全面复盘，所有上线需求均已完成单元测试覆盖，代码审查完成率 100%。", "blockers": "", "tomorrow_plan": "准备下阶段分布式任务调度中心与智能预警平台架构预研。", "today_completed": "配合团队主管完成本阶段研发任务全面复盘，所有上线需求均已完成单元测试覆盖，代码审查完成率 100%。"}', 8.0, 0, 'NORMAL', 1, 5, '2026-09-19 18:15:00', '2026-09-19 18:15:00');

-- work_log_tag_rel 表正式数据 (38 条)
INSERT INTO work_log_tag_rel (id, log_id, tag_id) VALUES
(1, 1, 1),
(2, 1, 5),
(3, 2, 3),
(4, 2, 5),
(5, 3, 1),
(6, 3, 7),
(7, 4, 2),
(8, 4, 9),
(9, 5, 3),
(10, 5, 6),
(11, 6, 1),
(12, 6, 7),
(13, 7, 1),
(14, 7, 8),
(15, 8, 1),
(16, 8, 4),
(17, 9, 3),
(18, 9, 10),
(19, 10, 1),
(20, 10, 7),
(21, 11, 2),
(22, 11, 9),
(23, 12, 2),
(24, 12, 5),
(25, 13, 3),
(26, 13, 7),
(27, 14, 1),
(28, 14, 8),
(29, 15, 1),
(30, 15, 10),
(31, 16, 3),
(32, 16, 5),
(33, 17, 1),
(34, 17, 7),
(35, 18, 4),
(36, 18, 9),
(37, 19, 4),
(38, 19, 10);

-- work_log_versions 表正式数据 (19 条)
INSERT INTO work_log_versions (id, log_id, version_num, operator_id, content_json, spent_hours, change_summary, is_rollback, created_at) VALUES
(1, 1, 1, 5, '{"task": "完成企业支付中台银联跨行清分批处理任务分片重构，编写分布式定时调度任务，优化 MySQL 慢查询索引，耗时从 4.2s 降至 85ms。", "blockers": "跨行对账批量拉取接口在大并发下偶发网络抖动超时，已增加重试退避机制。", "tomorrow_plan": "推进支付宝与微信渠道的统一支付流水幂等性校验模块编写。", "today_completed": "完成企业支付中台银联跨行清分批处理任务分片重构，编写分布式定时调度任务，优化 MySQL 慢查询索引，耗时从 4.2s 降至 85ms。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-01 18:15:00'),
(2, 2, 1, 6, '{"task": "完成交易分库分表 Sharding 分片键设计与数据字典规范拟定，搭建 Canal 监听 MySQL binlog 实现异构数据同步。", "blockers": "Canal 在大事务下存在 300ms 复制延迟，正排查写入阻塞点。", "tomorrow_plan": "编写交易流水冷热数据分离归档脚本，预计降低主库 40% 存储压力。", "today_completed": "完成交易分库分表 Sharding 分片键设计与数据字典规范拟定，搭建 Canal 监听 MySQL binlog 实现异构数据同步。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-01 18:15:00'),
(3, 3, 1, 7, '{"task": "完成协同工作台整体水墨国风组件库视觉框架搭建，基于纯 CSS 实现墨韵宣纸质感卡片与自适应栅格系统，完全剔除外部 CDN 依赖。", "blockers": "", "tomorrow_plan": "封装基于 Pinia 的用户多角色与权限路由守卫动态生成逻辑。", "today_completed": "完成协同工作台整体水墨国风组件库视觉框架搭建，基于纯 CSS 实现墨韵宣纸质感卡片与自适应栅格系统，完全剔除外部 CDN 依赖。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-01 18:15:00'),
(4, 4, 1, 8, '{"task": "编写 Locust 分布式全链路高并发压测脚本，对清结算 API 进行阶梯式增压测试，定位到连接池耗尽瓶颈。", "blockers": "压测过程中发现后端 asyncmy 数据库连接池满载抛出超时，需协同后端调优池上限。", "tomorrow_plan": "协助后端工程师验证连接池参数调优后的 3000 QPS 稳定运行指标。", "today_completed": "编写 Locust 分布式全链路高并发压测脚本，对清结算 API 进行阶梯式增压测试，定位到连接池耗尽瓶颈。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-02 18:15:00'),
(5, 5, 1, 5, '{"task": "重构支付网关接入层，引入基于 Redis 令牌桶算法的防刷限流中间件，完成基于 BCrypt 加盐鉴权的安全审计拦截。", "blockers": "测试环境发现 Redis 集群在主从切换瞬间存在短暂连接中断，已配置 pool_pre_ping 保活机制。", "tomorrow_plan": "优化订单结算事务边界，拆解长事务为两阶段轻量操作，减少行锁持有时间。", "today_completed": "重构支付网关接入层，引入基于 Redis 令牌桶算法的防刷限流中间件，完成基于 BCrypt 加盐鉴权的安全审计拦截。"}', 8.5, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-02 18:15:00'),
(6, 6, 1, 7, '{"task": "实现前端工作日志管理（笔部）工作台布局，完成卡点三关看板（待排查/攻坚中/已闭环）拖拽交互与状态更新。", "blockers": "ECharts 工时热力图日历组件在移动端响应式布局时存在图表重绘抖动，已通过 ResizeObserver 防抖修复。", "tomorrow_plan": "完成复盘驾驶舱四扇屏风（KISS 四象限）组件的响应式布局封装。", "today_completed": "实现前端工作日志管理（笔部）工作台布局，完成卡点三关看板（待排查/攻坚中/已闭环）拖拽交互与状态更新。"}', 7.5, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-03 18:15:00'),
(7, 7, 1, 10, '{"task": "完成大模型统一智能网关适配层搭建，统一封装 OpenAI、DeepSeek 与 Qwen 的流式通信接口，支持 SSE 打字机流式输出。", "blockers": "外部大模型 API 在高峰期可能出现限流或响应超时，设计了基于本地高仿真沙箱的无缝自动降级兜底方案。", "tomorrow_plan": "编写提示词模板动态注入引擎，支持根据团队多维日志自动构建 KISS 结构化 Prompt。", "today_completed": "完成大模型统一智能网关适配层搭建，统一封装 OpenAI、DeepSeek 与 Qwen 的流式通信接口，支持 SSE 打字机流式输出。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-03 18:15:00'),
(8, 8, 1, 5, '{"task": "完成工作日志历史版本时光机追溯与版本回滚 API 开发，利用 MySQL 原生 JSON 字段存储完整内容快照与工时演进记录。", "blockers": "", "tomorrow_plan": "协助前端联调时光机抽屉界面与版本差异对比功能。", "today_completed": "完成工作日志历史版本时光机追溯与版本回滚 API 开发，利用 MySQL 原生 JSON 字段存储完整内容快照与工时演进记录。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-04 18:15:00'),
(9, 9, 1, 6, '{"task": "完成分布式事务 Seata AT 模式接入测试，针对支付结算中扣减余额与生成流水跨库场景进行幂等防重保障。", "blockers": "分支事务在网络分区时偶发全局锁冲突，调整事务重试间隔与隔离级别。", "tomorrow_plan": "编写支付中心异常交易自动对账与告警补偿作业。", "today_completed": "完成分布式事务 Seata AT 模式接入测试，针对支付结算中扣减余额与生成流水跨库场景进行幂等防重保障。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-07 18:15:00'),
(10, 10, 1, 7, '{"task": "实现复盘决议改进事项（Action Items）军令状看板与完成凭据上报弹窗，集成全局统一中文友好通知反馈。", "blockers": "部分表单输入框在极速回车提交时存在防抖失效重复触发，已添加按钮 loading 与防重复提交指令。", "tomorrow_plan": "联调墨部研发效能度量大屏，接入工时燃尽折线图与五维能力雷达图。", "today_completed": "实现复盘决议改进事项（Action Items）军令状看板与完成凭据上报弹窗，集成全局统一中文友好通知反馈。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-08 18:15:00'),
(11, 11, 1, 8, '{"task": "执行企业门户与支付中台跨团队集成回归测试用例 240 项，自动化通过率 98.3%，发现并闭环缺陷 4 处。", "blockers": "发现日志附件上传在校验魔数时对大文件耗时较长，建议后端引入分片嗅探机制。", "tomorrow_plan": "编写安全渗透测试报告，验证防 SQL 注入与防横向越权行级过滤。", "today_completed": "执行企业门户与支付中台跨团队集成回归测试用例 240 项，自动化通过率 98.3%，发现并闭环缺陷 4 处。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-09 18:15:00'),
(12, 12, 1, 5, '{"task": "排查并修复异步数据库引擎连接泄漏问题，完善 SQLAlchemy 2.0 上下文管理器，确保每次请求精准关闭连接。", "blockers": "早期未配置 pool_recycle 导致 MySQL 8 小时空闲超时断连，现已在 config.py 统一注入保活参数。", "tomorrow_plan": "配合团队主管筹备 9 月上旬系统架构演进 KISS 复盘汇报数据准备。", "today_completed": "排查并修复异步数据库引擎连接泄漏问题，完善 SQLAlchemy 2.0 上下文管理器，确保每次请求精准关闭连接。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-10 18:15:00'),
(13, 13, 1, 7, '{"task": "优化前端生产构建配置，引入 Rollup manualChunks 进行动态分包，将 vendor.js 体积从 1.2MB 优化至 420kB，首屏秒开率提升 65%。", "blockers": "", "tomorrow_plan": "整理前端 UI 设计规范与视觉风格指南文档，统一全平台设计规范。", "today_completed": "优化前端生产构建配置，引入 Rollup manualChunks 进行动态分包，将 vendor.js 体积从 1.2MB 优化至 420kB，首屏秒开率提升 65%。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-11 18:15:00'),
(14, 14, 1, 10, '{"task": "完成智能复盘引擎中的结晶算法优化，采用 jieba 结巴分词与 TF-IDF 权重提取团队全员日志中的高频卡点词，按严重度自动聚类。", "blockers": "部分通用词（如\'完成\'、\'修复\'）需要停用词过滤字典过滤，已配置专用企业技术停用词表。", "tomorrow_plan": "支持一键下发复盘改进项（Action Items）至责任人并自动发送企业微信通知。", "today_completed": "完成智能复盘引擎中的结晶算法优化，采用 jieba 结巴分词与 TF-IDF 权重提取团队全员日志中的高频卡点词，按严重度自动聚类。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-14 18:15:00'),
(15, 15, 1, 5, '{"task": "完成清结算中台与微信支付 V3 接口对账自动化流水生成，支持按批次导出格式化公文级 Word 复盘报告与对账单据。", "blockers": "", "tomorrow_plan": "完善主管日志审阅一键评星与快捷富文本批注后端接口。", "today_completed": "完成清结算中台与微信支付 V3 接口对账自动化流水生成，支持按批次导出格式化公文级 Word 复盘报告与对账单据。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-15 18:15:00'),
(16, 16, 1, 6, '{"task": "完成生产级只读从库读写分离路由适配，在高并发报表统计与效能大屏查询时自动切入从库，保护主库核心交易事务。", "blockers": "主从数据同步在网络压力骤增时存在微秒级延迟，在强一致性查询时已配置强制路由主库注解。", "tomorrow_plan": "编写数据库表定期归档与冷备份自动化 shell 脚本。", "today_completed": "完成生产级只读从库读写分离路由适配，在高并发报表统计与效能大屏查询时自动切入从库，保护主库核心交易事务。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-16 18:15:00'),
(17, 17, 1, 7, '{"task": "完成系统墨部研发效能全景大屏的秒开优化，接入后端每日定时快照预计算数据，规避了全表扫描与复杂聚合查询。", "blockers": "", "tomorrow_plan": "配合各组主管进行多团队数据行级权限隔离验收。", "today_completed": "完成系统墨部研发效能全景大屏的秒开优化，接入后端每日定时快照预计算数据，规避了全表扫描与复杂聚合查询。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-17 18:15:00'),
(18, 18, 1, 8, '{"task": "完成 5000 QPS 高负载全链路压测第二轮验收，系统平均响应时间维持在 32ms，P99 时延 < 85ms，CPU 与内存利用率平稳保持在 60% 以下。", "blockers": "", "tomorrow_plan": "输出《端到端全链路性能压测与架构高可用达标报告》。", "today_completed": "完成 5000 QPS 高负载全链路压测第二轮验收，系统平均响应时间维持在 32ms，P99 时延 < 85ms，CPU 与内存利用率平稳保持在 60% 以下。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-18 18:15:00'),
(19, 19, 1, 5, '{"task": "配合团队主管完成本阶段研发任务全面复盘，所有上线需求均已完成单元测试覆盖，代码审查完成率 100%。", "blockers": "", "tomorrow_plan": "准备下阶段分布式任务调度中心与智能预警平台架构预研。", "today_completed": "配合团队主管完成本阶段研发任务全面复盘，所有上线需求均已完成单元测试覆盖，代码审查完成率 100%。"}', 8.0, '初次提交日常研发工作产出与卡点汇报', 0, '2026-09-19 18:15:00');

-- work_log_comments 表正式数据 (6 条)
INSERT INTO work_log_comments (id, log_id, author_id, content, score_rating, created_at) VALUES
(1, 1, 2, '分片批处理算法设计合理，慢查询从 4.2s 压降至 85ms 效果极其显著，明天架构周会请向全组做一次经验技术分享！', 5, '2026-09-01 19:30:00'),
(2, 2, 2, 'Sharding 方案符合公司中台规范，Canal 延迟问题可参考配置 batchSize 优化，整体方案通过。', 4, '2026-09-01 20:10:00'),
(3, 3, 3, '纯 CSS 水墨国风组件库视觉效果极佳，摆脱外部 CDN 依赖确保了企业级交付的高可靠性，点赞！', 5, '2026-09-02 09:15:00'),
(4, 5, 2, '令牌桶防刷与 BCrypt 安全加固做得非常扎实，注意观察高并发峰值时的内存占用情况。', 5, '2026-09-02 21:00:00'),
(5, 12, 2, '排查很细致，连接池泄漏问题已彻底解决，线上稳定性指标达标。', 5, '2026-09-10 20:00:00'),
(6, 18, 4, '全链路压测 5000 QPS 顺利达标，P99 时延表现出色，为大促打下了坚实基础，测试组全体同学辛苦！', 5, '2026-09-18 19:45:00');

-- retrospective_templates 表正式数据 (2 条)
INSERT INTO retrospective_templates (id, name, model_framework, prompt_system, prompt_template, is_active, created_at) VALUES
(1, 'KISS 敏捷团队复盘模型', 'KISS', '你是一名资深敏捷架构专家。请基于输入的团队日志，严格按照 KISS 模型（Keep/Improve/Start/Stop）进行结构化提炼并输出 Action Items 清单。', '请分析以下团队工作日志数据：
${teamLogs}

请按 JSON 格式输出复盘报告。', 1, '2026-09-20 10:40:11'),
(2, 'GRAI 目标与偏差归因复盘法', 'GRAI', '你是一名现代企业管理学专家，擅长使用 GRAI 复盘法（目标回顾、结果比对、过程审视、规律提炼）剖析交付偏差。', '请分析周期内工作日志与交付成果：
${teamLogs}

请输出 GRAI 维度复盘分析报告。', 1, '2026-09-20 10:40:11');

-- retrospective_reports 表正式数据 (2 条)
INSERT INTO retrospective_reports (id, team_id, creator_id, template_id, ai_model_id, title, scope_type, start_date, end_date, ai_draft, final_content, kiss_structured_json, blocker_keywords, status, error_message, created_at, updated_at) VALUES
(1, 1, 2, 1, NULL, '后端研发组9月中旬系统架构与效能演进KISS复盘', 'TEAM', '2026-09-01', '2026-09-14', '【后端研发组 · 9月中旬架构演进与交付复盘总结】
在 2026-09-01 至 2026-09-14 交付周期内，团队共计提交 12 篇核心研发日志，总投入工时 96.5 小时。重点攻坚了支付清结算分库分表改造、分布式缓存集群稳定性和异步连接池保活，系统在全链路压测中成功承受 5000 QPS 极限负载，平均时延 32ms，各项稳定性指标完全达标。针对跨端联调文档同步及生产打包体积等改进项，已制定 4 项专项行动军令状并锁定责任人推进闭环。', '【后端研发组 · 9月中旬架构演进与交付复盘总结】
在 2026-09-01 至 2026-09-14 交付周期内，团队共计提交 12 篇核心研发日志，总投入工时 96.5 小时。重点攻坚了支付清结算分库分表改造、分布式缓存集群稳定性和异步连接池保活，系统在全链路压测中成功承受 5000 QPS 极限负载，平均时延 32ms，各项稳定性指标完全达标。针对跨端联调文档同步及生产打包体积等改进项，已制定 4 项专项行动军令状并锁定责任人推进闭环。', '{"keep": ["严格执行模块化单体架构设计规范，各领域高内聚低耦合，单机内存负载平稳保持在 80MB 以下", "团队工作日志填报与热力日历机制运转顺畅，核心研发骨干准时提交率稳定达 96.5% 以上", "数据库异步连接池 pool_pre_ping 保活与连接回收机制有效杜绝了长连接断开与连接泄漏问题"], "stop": ["彻底停止在生产与核心交付环境直接引入不可控的外部第三方 CDN 脚本依赖", "停止在没有异常拦截捕获与保活沙箱的情况下直连外部不可控微服务", "停止无明确具体责任人 (Assignee) 和确切截止日期的口头复盘改进承诺"], "start": ["全面推行 SSE 实时流式响应与 Token 吞吐审计，提升 AI 智能推演交互响应体验", "建立每日定时自动构建防回归验证体系，将全链路压测断言集成至发布流水线", "在日志填报中引入 AI 自动提取高频卡点词频云图，实现研发障碍自动化聚类"], "improve": ["跨团队联调阶段接口文档同步有时存在滞后，部分接口字段需提前冻结以减少联调摩擦", "大文件及复杂附件上传校验二进制魔数逻辑在极端并发下仍有约 150ms 优化空间", "复盘行动项 (Action Items) 逾期提醒机制需进一步联动企业微信机器人实现点对点催交"]}', '[{"word": "异步连接池超时", "count": 14, "severity": "HIGH"}, {"word": "跨域 CORS 拦截", "count": 9, "severity": "MEDIUM"}, {"word": "生产打包体积超标", "count": 8, "severity": "MEDIUM"}, {"word": "接口文档未同步", "count": 6, "severity": "LOW"}, {"word": "测试用例覆盖不全", "count": 4, "severity": "LOW"}]', 'SUCCESS', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(2, 2, 3, 1, NULL, '企业一体化协同工作台V3.0前端交互体验复盘', 'TEAM', '2026-09-01', '2026-09-15', '【前端与跨端应用组 · 协同工作台V3.0界面体验复盘】
周期内重点完成了水墨国风组件库封装与构建体积优化。通过纯 CSS 替换外部样式库，实现了 100% 离线可用，同时通过 Rollup 分包将首屏 JS 大小压缩 65%，交互流畅度达到 60fps 满帧。', '【前端与跨端应用组 · 协同工作台V3.0界面体验复盘】
周期内重点完成了水墨国风组件库封装与构建体积优化。通过纯 CSS 替换外部样式库，实现了 100% 离线可用，同时通过 Rollup 分包将首屏 JS 大小压缩 65%，交互流畅度达到 60fps 满帧。', '{"keep": ["纯 CSS 墨韵组件库完全自研", "Pinia 状态持久化与 Token 无感刷新机制完备"], "stop": ["停止混用内联样式与全局未命名样式"], "start": ["引入动态主题色变量切换能力", "增加首屏加载骨架屏过渡效果"], "improve": ["部分复杂图表在超宽屏显示器下的缩放比例需微调", "移动端抽屉遮罩层层级控制需规范"]}', '[{"word": "异步连接池超时", "count": 14, "severity": "HIGH"}, {"word": "跨域 CORS 拦截", "count": 9, "severity": "MEDIUM"}, {"word": "生产打包体积超标", "count": 8, "severity": "MEDIUM"}, {"word": "接口文档未同步", "count": 6, "severity": "LOW"}, {"word": "测试用例覆盖不全", "count": 4, "severity": "LOW"}]', 'SUCCESS', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11');

-- retrospective_action_items 表正式数据 (6 条)
INSERT INTO retrospective_action_items (id, report_id, team_id, assignee_id, title, description, deadline, status, result_summary, completed_at, created_at, updated_at) VALUES
(1, 1, 1, 3, '搭建离线化 Zero-CDN 前端构建流程与纯 CSS 视觉规范', '去除所有外部 CDN 依赖，整合字体与组件资源至本地，确保答辩与断网 100% 秒级可用', '2026-09-22', 'DOING', '已完成全库依赖排查并完成静态化构建测试', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(2, 1, 1, 5, '完善复盘行动项自动逾期状态机调度作业', '针对 status 为 TODO/DOING 的逾期行动项，自动标记 OVERDUE 并生成站内信推送', '2026-09-21', 'DONE', '调度作业已上线并通过单元测试，自动化率 100%', '2026-09-20 10:00:00', '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(3, 1, 1, 6, '支付微服务异步回调网络抖动指数退避重试机制上线', '基于 Redis 与 RabbitMQ 实现三次阶梯退避重试，杜绝偶发网络抖动导致丢单', '2026-09-24', 'TODO', NULL, NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(4, 1, 1, 8, '全链路压测平台 5000 QPS 极限负载验收与熔断限流校准', '在仿真测试环境完成梯度加压，校准核心网关降级保护阈值', '2026-09-23', 'DOING', '已完成 3000 QPS 基线压测，正向 5000 QPS 攻坚', NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(5, 2, 2, 7, '协同工作台 ECharts 图表在移动端自适应防抖重绘完善', '监听屏幕旋转与窗口 resize 事件，加入 200ms 防抖确保移动端图表渲染平滑', '2026-09-25', 'TODO', NULL, NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11'),
(6, 1, 1, 5, '梳理并导出企业支付中台公文级技术交接文档', '调用 python-docx 模块生成标准格式公文报告，提交技术委员会评审', '2026-09-26', 'TODO', NULL, NULL, '2026-09-20 10:40:11', '2026-09-20 10:40:11');

-- daily_stat_snapshots 表正式数据 (14 条)
INSERT INTO daily_stat_snapshots (id, snapshot_date, team_id, expected_count, actual_count, on_time_count, delayed_count, submission_rate, total_spent_hours, project_hours_json, blocker_count, created_at) VALUES
(1, '2026-09-01', 1, 3, 3, 2, 1, 96.67, 22.5, '{"PROJ_PAY": 22.5}', 1, '2026-09-20 10:40:11'),
(2, '2026-09-02', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 0, '2026-09-20 10:40:11'),
(3, '2026-09-03', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 1, '2026-09-20 10:40:11'),
(4, '2026-09-04', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 0, '2026-09-20 10:40:11'),
(5, '2026-09-07', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 1, '2026-09-20 10:40:11'),
(6, '2026-09-08', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 0, '2026-09-20 10:40:11'),
(7, '2026-09-09', 1, 3, 3, 2, 1, 96.67, 22.5, '{"PROJ_PAY": 22.5}', 1, '2026-09-20 10:40:11'),
(8, '2026-09-10', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 0, '2026-09-20 10:40:11'),
(9, '2026-09-11', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 1, '2026-09-20 10:40:11'),
(10, '2026-09-14', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 0, '2026-09-20 10:40:12'),
(11, '2026-09-15', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 1, '2026-09-20 10:40:12'),
(12, '2026-09-16', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 0, '2026-09-20 10:40:12'),
(13, '2026-09-17', 1, 3, 3, 2, 1, 96.67, 22.5, '{"PROJ_PAY": 22.5}', 1, '2026-09-20 10:40:12'),
(14, '2026-09-18', 1, 3, 3, 3, 0, 100.00, 24.0, '{"PROJ_PAY": 24.0}', 0, '2026-09-20 10:40:12');

-- notifications 表正式数据 (5 条)
INSERT INTO notifications (id, user_id, team_id, title, content, notify_type, is_read, channel, wechat_send_status, created_at) VALUES
(1, 1, 1, '【AI 基础设施通报】端溪古砚大模型统一智能网关已就绪', 'DeepSeek 与 Qwen 双通道已完成挂载，支持流式 SSE 输出与离线高仿真沙箱自动兜底。', 'SYSTEM', 0, 'ALL', 'SENT', '2026-09-20 10:40:12'),
(2, 2, 1, '【复盘决议通知】9月中旬架构演进复盘报告已正式发布', 'KISS 四象限决策已锁定，请相关责任人及时登录认领改进行动军令状。', 'RETROSPECTIVE', 0, 'ALL', 'SENT', '2026-09-20 10:40:12'),
(3, 5, 1, '【主管批注提醒】张建国主管对您昨日日志进行了评星与专业批注', '张建国：分片批处理算法设计合理，慢查询降低效果显著，请明日组织经验分享。', 'COMMENT', 0, 'ALL', 'SENT', '2026-09-20 10:40:12'),
(4, 7, 2, '【效能大屏更新】前端研发组件库构建体积优化成果已并入看板', 'Rollup 分包使静态资源体积缩小 65%，首屏渲染指标已达标。', 'REMINDER', 0, 'ALL', 'SENT', '2026-09-20 10:40:12'),
(5, 8, 3, '【全链路压测通过】企业统一支付中台 5000 QPS 压测达标', '测试组已完成第二轮梯度负载验收，各指标平稳通过技术委员会初审。', 'ALERT', 0, 'ALL', 'SENT', '2026-09-20 10:40:12');

-- work_calendars 表正式数据 (30 条)
INSERT INTO work_calendars (id, calendar_date, is_workday, day_type, note, created_at) VALUES
(1, '2026-09-01', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(2, '2026-09-02', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(3, '2026-09-03', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(4, '2026-09-04', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(5, '2026-09-05', 0, 'WEEKEND', '周末公休', '2026-09-20 10:40:12'),
(6, '2026-09-06', 0, 'WEEKEND', '周末公休', '2026-09-20 10:40:12'),
(7, '2026-09-07', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(8, '2026-09-08', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(9, '2026-09-09', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(10, '2026-09-10', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(11, '2026-09-11', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(12, '2026-09-12', 0, 'WEEKEND', '周末公休', '2026-09-20 10:40:12'),
(13, '2026-09-13', 0, 'WEEKEND', '周末公休', '2026-09-20 10:40:12'),
(14, '2026-09-14', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(15, '2026-09-15', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(16, '2026-09-16', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(17, '2026-09-17', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(18, '2026-09-18', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(19, '2026-09-19', 0, 'WEEKEND', '周末公休', '2026-09-20 10:40:12'),
(20, '2026-09-20', 0, 'WEEKEND', '周末公休', '2026-09-20 10:40:12'),
(21, '2026-09-21', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(22, '2026-09-22', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(23, '2026-09-23', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(24, '2026-09-24', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(25, '2026-09-25', 0, 'HOLIDAY', '中秋节法定假日', '2026-09-20 10:40:12'),
(26, '2026-09-26', 0, 'WEEKEND', '周末公休', '2026-09-20 10:40:12'),
(27, '2026-09-27', 0, 'WEEKEND', '周末公休', '2026-09-20 10:40:12'),
(28, '2026-09-28', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(29, '2026-09-29', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12'),
(30, '2026-09-30', 1, 'WORKDAY', NULL, '2026-09-20 10:40:12');

-- audit_logs 表正式数据 (4 条)
INSERT INTO audit_logs (id, team_id, operator_id, operator_name, action_type, resource_target, ip_address, user_agent, status, extra_json, created_at) VALUES
(1, 1, 1, '系统超级管理员', 'USER_LOGIN', '认证中枢', '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', 'SUCCESS', '{"action": "管理员密码鉴权成功"}', '2026-09-20 10:40:12'),
(2, 1, 2, '张建国 (后端架构师)', 'GENERATE_RETROSPECTIVE', '复盘引擎', '192.168.1.102', 'Chrome/128.0.0.0', 'SUCCESS', '{"framework": "KISS", "report_id": 1}', '2026-09-20 10:40:12'),
(3, 1, 2, '张建国 (后端架构师)', 'COMMENT_WORK_LOG', '日志审阅', '192.168.1.102', 'Chrome/128.0.0.0', 'SUCCESS', '{"score": 5, "log_id": 1}', '2026-09-20 10:40:12'),
(4, 2, 3, '李晓华 (前端技术主管)', 'UPDATE_PROJECT_STATUS', '项目管理', '192.168.1.105', 'Chrome/128.0.0.0', 'SUCCESS', '{"new_status": "IN_PROGRESS", "project_id": 2}', '2026-09-20 10:40:12');

-- ai_model_configs 表正式数据 (3 条)
INSERT INTO ai_model_configs (id, provider_name, model_identifier, api_base_url, api_key, context_window, max_tokens, temperature, is_default, is_active, created_at, updated_at) VALUES
(1, 'DeepSeek', 'deepseek-chat', 'https://api.deepseek.com/v1', 'sk-dseek-enterprise-formal-key', 65536, 4096, 0.7, 1, 1, '2026-09-20 10:40:12', '2026-09-20 10:40:12'),
(2, 'Qwen', 'qwen-max', 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'sk-qwen-enterprise-formal-key', 32768, 4096, 0.7, 0, 1, '2026-09-20 10:40:12', '2026-09-20 10:40:12'),
(3, 'Ollama(离线中枢)', 'deepseek-r1:7b', 'http://localhost:11434/v1', 'ollama-local-token', 16384, 2048, 0.5, 0, 1, '2026-09-20 10:40:12', '2026-09-20 10:40:12');

-- system_configs 表正式数据 (6 条)
INSERT INTO system_configs (id, config_key, config_value, description, is_secret, updated_at) VALUES
(1, 'PASSWORD_MAX_EXPIRED_DAYS', '90', '密码最长有效天数 (0表示永不过期)', 0, '2026-09-20 10:40:12'),
(2, 'LOGIN_MAX_FAILED_ATTEMPTS', '5', '密码连续错误最大次数阈值', 0, '2026-09-20 10:40:12'),
(3, 'LOGIN_LOCK_MINUTES', '15', '密码错误超限锁定时长 (分钟)', 0, '2026-09-20 10:40:12'),
(4, 'WECHAT_PUSH_ENABLE', 'false', '企业微信外部推送总开关', 0, '2026-09-20 10:40:12'),
(5, 'WECHAT_WEBHOOK_URL', 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=prod-key', '企业微信群机器人推送Webhook地址', 1, '2026-09-20 10:40:12'),
(6, 'DAILY_LOG_REMIND_TIME', '17:30', '工作日每日日志催交自动提醒时点', 0, '2026-09-20 10:40:12');

SET FOREIGN_KEY_CHECKS = 1;
