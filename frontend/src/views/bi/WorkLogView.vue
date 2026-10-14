<template>
  <div class="bi-view">
    <!-- 头部栏 (现代 SaaS 页面标题) -->
    <div class="view-hero-bar">
      <div>
        <div class="hero-tag-row">
          <span class="badge badge-primary">研发核心工作台</span>
          <span class="text-secondary" style="font-size: 12px;">实时数据已对齐</span>
        </div>
        <h1 class="hero-title">工作日志管理与排障工作台</h1>
        <p class="hero-desc">规范化日常研发填报 · 敏捷卡点治理 · 版本时光机追溯回滚</p>
      </div>
      <div class="hero-actions">
        <button @click="showCreateModal = true" class="btn btn-primary">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
          </svg>
          填报今日日志
        </button>
      </div>
    </div>

    <!-- 上半部分：2 列网格 (左侧：快速填报 + 工时热力；右侧：技术阻碍三关看板) -->
    <div class="grid-top">
      <!-- 左列：组件 1 + 组件 2 -->
      <div class="left-col">
        <!-- 组件 1: 快速填写工作日志卡片 -->
        <WorklogFormCard 
          :projects="projects"
          :templates="templates"
          @submitted="handleLogSubmitted"
        />

        <!-- 组件 2: 工时投入趋势热力日历卡片 -->
        <HeatmapCalendarCard 
          ref="heatmapRef"
          @day-click="handleDayClick"
        />
      </div>

      <!-- 右列：组件 3 (技术阻碍排障三关看板: 待排查/攻坚中/已闭环) -->
      <div class="right-col">
        <BlockerKanbanCard :blockers="blockers" />
      </div>
    </div>

    <!-- 下半部分：组件 4 (团队全员近期工作日志提交流水表格) -->
    <div style="margin-top: 24px;">
      <TeamWorklogListCard 
        :logs="logs"
        :projects="projects"
        :is-leader="authStore.isLeader"
        @refresh="fetchLogs"
        @view-detail="viewDetail"
        @score="openScoreModal"
      />

    </div>

    <!-- 弹窗：填报新日志 Modal -->
    <div v-if="showCreateModal" class="modal-backdrop">
      <div class="modal-card">
        <div class="modal-header">
          <div class="modal-title">填报工作日志</div>
          <button @click="showCreateModal = false" class="btn-close">×</button>
        </div>

        <form @submit.prevent="submitLogModal" class="modal-form">
          <div class="form-row">
            <div class="form-group flex-1">
              <label class="form-label">日志归属日期</label>
              <input v-model="createForm.log_date" type="date" class="form-input" required />
            </div>
            <div class="form-group flex-1">
              <label class="form-label">投入总工时 (h)</label>
              <input v-model.number="createForm.spent_hours" type="number" step="0.5" min="1" max="24" class="form-input" required />
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">关联企业项目</label>
            <select v-model="createForm.project_id" class="form-select">
              <option :value="null">通用任务 / 无特定项目</option>
              <option v-for="p in projects" :key="p.id" :value="p.id">{{ p.name }} ({{ p.code }})</option>
            </select>
          </div>

          <div class="form-group">
            <label class="form-label">今日主要攻坚事项</label>
            <textarea v-model="createForm.content_json.task" class="form-textarea" rows="3" placeholder="详细列出今日完成的核心研发、测试或架构工作..." required></textarea>
          </div>

          <div class="form-group">
            <label class="form-label">遇到的阻碍 / 卡点 (可选)</label>
            <textarea v-model="createForm.content_json.blockers" class="form-textarea" rows="2" placeholder="如有阻碍联调或架构问题请在此填写，将同步汇入攻坚看板..."></textarea>
          </div>

          <div class="form-group">
            <label class="form-label">明日工作计划</label>
            <input v-model="createForm.content_json.tomorrow_plan" class="form-input" placeholder="简述次日重点推进事项" />
          </div>

          <div class="modal-footer">
            <button type="button" @click="showCreateModal = false" class="btn btn-secondary">取消</button>
            <button type="submit" class="btn btn-primary" :disabled="submitting">
              {{ submitting ? '正在提交...' : '确认提交' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- 日志详情与版本时光机 Drawer -->
    <div v-if="showDetailDrawer && currentDetail" class="modal-backdrop">
      <div class="modal-card detail-drawer">
        <div class="modal-header">
          <div class="modal-title">
            日志详情 (v{{ currentDetail.current_version }}) · {{ currentDetail.log_date }}
          </div>
          <button @click="showDetailDrawer = false" class="btn-close">×</button>
        </div>

        <div class="drawer-body">
          <div class="detail-section">
            <div class="detail-label">填报信息</div>
            <div class="detail-value">
              <strong>{{ currentDetail.author_name }}</strong> · 所属项目：{{ currentDetail.project_name || '通用研发' }} · 投入工时：{{ currentDetail.spent_hours }}h
            </div>
          </div>

          <div class="detail-section">
            <div class="detail-label">今日工作内容</div>
            <div class="detail-box">{{ currentDetail.content_json?.task || '无' }}</div>
          </div>

          <div v-if="currentDetail.content_json?.blockers" class="detail-section">
            <div class="detail-label" style="color: var(--danger);">阻碍与技术卡点</div>
            <div class="detail-box blocker-box">{{ currentDetail.content_json.blockers }}</div>
          </div>

          <!-- 版本历史时光机 -->
          <div class="detail-section" style="margin-top: 20px;">
            <div class="detail-label" style="display: flex; justify-content: space-between; align-items: center;">
              <span>版本演进时光机 (共 {{ currentDetail.versions?.length || 0 }} 个快照)</span>
            </div>

            <div class="version-timeline">
              <div v-for="v in currentDetail.versions" :key="v.id" class="ver-item">
                <div class="ver-head">
                  <span class="badge badge-primary">v{{ v.version_num }}</span>
                  <span class="ver-time">{{ v.created_at?.slice(0, 16) }} · {{ v.operator_name }}</span>
                  <button 
                    v-if="v.version_num !== currentDetail.current_version" 
                    @click="handleRollback(currentDetail.id, v.version_num)"
                    class="btn btn-secondary btn-sm"
                  >
                    时光机回滚
                  </button>
                </div>
                <div class="ver-summary">{{ v.change_summary }}</div>
              </div>
            </div>
          </div>

          <!-- 评论批注区 -->
          <div class="detail-section" style="margin-top: 20px;">
            <div class="detail-label">主管批注与互动</div>
            <div class="comments-list">
              <div v-if="!currentDetail.comments?.length" class="empty-hint">暂无主管批注</div>
              <div v-for="c in currentDetail.comments" :key="c.id" class="comment-item">
                <div class="comment-head">
                  <strong class="comment-author">{{ c.author_name }}</strong>
                  <span v-if="c.score_rating" class="score-stars">★ {{ c.score_rating }} 星</span>
                  <span class="comment-date">{{ c.created_at?.slice(0, 16) }}</span>
                </div>
                <div class="comment-text">{{ c.content }}</div>
              </div>
            </div>

            <!-- 发表批注 -->
            <div class="add-comment-box" style="margin-top: 12px;">
              <input 
                v-model="commentText" 
                class="form-input" 
                placeholder="输入主管批注内容并按回车提交..." 
                @keyup.enter="submitComment" 
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 打分 Modal -->
    <div v-if="showScoreModal && scoringLog" class="modal-backdrop">
      <div class="modal-card" style="max-width: 380px;">
        <div class="modal-header">
          <div class="modal-title">主管评星打分</div>
          <button @click="showScoreModal = false" class="btn-close">×</button>
        </div>
        <div style="text-align: center; padding: 20px 0;">
          <div style="font-size: 13px; color: var(--text-muted); margin-bottom: 12px;">
            评定 <strong>{{ scoringLog.author_name }}</strong> 在 {{ scoringLog.log_date }} 的日志质量：
          </div>
          <div class="star-selector">
            <span 
              v-for="star in 5" 
              :key="star" 
              @click="targetScore = star"
              class="star-btn"
              :class="{ active: star <= targetScore }"
            >★</span>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="showScoreModal = false" class="btn btn-secondary">取消</button>
          <button @click="submitScore" class="btn btn-primary">保存评分</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import WorklogFormCard from '../../components/bi/WorklogFormCard.vue'
import HeatmapCalendarCard from '../../components/bi/HeatmapCalendarCard.vue'
import BlockerKanbanCard from '../../components/bi/BlockerKanbanCard.vue'
import TeamWorklogListCard from '../../components/bi/TeamWorklogListCard.vue'
import { 
  getWorkLogsApi, getWorkLogDetailApi, createWorkLogApi, 
  rollbackWorkLogApi, addCommentApi, scoreWorkLogApi,
  getTemplatesApi, getTagsApi, getBlockersApi 
} from '../../api/workLogs'
import { getProjectsApi } from '../../api/projects'

const authStore = useAuthStore()

const todayStr = new Date().toISOString().slice(0, 10)
const heatmapRef = ref(null)

const blockers = ref([])
const logs = ref([])
const projects = ref([])
const templates = ref([])
const tags = ref([])

const showCreateModal = ref(false)
const submitting = ref(false)
const createForm = reactive({
  template_id: 1,
  project_id: null,
  log_date: todayStr,
  spent_hours: 8.0,
  content_json: {
    task: '',
    blockers: '',
    tomorrow_plan: ''
  },
  tag_ids: []
})

const showDetailDrawer = ref(false)
const currentDetail = ref(null)
const commentText = ref('')

const showScoreModal = ref(false)
const scoringLog = ref(null)
const targetScore = ref(5)

const fetchBlockers = async () => {
  try {
    const res = await getBlockersApi()
    blockers.value = res || []
  } catch (e) {
    console.error(e)
  }
}

const fetchLogs = async () => {
  try {
    const res = await getWorkLogsApi({ page: 1, page_size: 30 })
    logs.value = res.items || []
  } catch (e) {
    console.error(e)
  }
}

const fetchBaseData = async () => {
  try {
    const [p, t, tg] = await Promise.all([
      getProjectsApi(),
      getTemplatesApi(),
      getTagsApi()
    ])
    projects.value = p || []
    templates.value = t || []
    tags.value = tg || []
    if (templates.value.length > 0) {
      createForm.template_id = templates.value[0].id
    }
  } catch (e) {
    console.error(e)
  }
}

const handleLogSubmitted = () => {
  fetchLogs()
  heatmapRef.value?.fetchHeatmap()
  fetchBlockers()
}

const handleDayClick = (day) => {
  if (day.log_id) {
    viewDetail(day.log_id)
  } else {
    createForm.log_date = day.date
    showCreateModal.value = true
  }
}

const submitLogModal = async () => {
  submitting.value = true
  try {
    await createWorkLogApi(createForm)
    showCreateModal.value = false
    handleLogSubmitted()
  } catch (e) {
    alert(e.message)
  } finally {
    submitting.value = false
  }
}

const viewDetail = async (id) => {
  try {
    const res = await getWorkLogDetailApi(id)
    currentDetail.value = res
    showDetailDrawer.value = true
  } catch (e) {
    alert(e.message)
  }
}

const handleRollback = async (logId, versionNum) => {
  if (!confirm(`确认要将此日志回滚至历史版本 v${versionNum} 吗？`)) return
  try {
    await rollbackWorkLogApi(logId, { target_version: versionNum, reason: '时光机版本历史回滚' })
    viewDetail(logId)
    fetchLogs()
  } catch (e) {
    alert(e.message)
  }
}

const submitComment = async () => {
  if (!commentText.value.trim() || !currentDetail.value) return
  try {
    await addCommentApi(currentDetail.value.id, { content: commentText.value })
    commentText.value = ''
    viewDetail(currentDetail.value.id)
  } catch (e) {
    alert(e.message)
  }
}

const openScoreModal = (log) => {
  scoringLog.value = log
  targetScore.value = log.score || 5
  showScoreModal.value = true
}

const submitScore = async () => {
  if (!scoringLog.value) return
  try {
    await scoreWorkLogApi(scoringLog.value.id, targetScore.value)
    showScoreModal.value = false
    fetchLogs()
  } catch (e) {
    alert(e.message)
  }
}

onMounted(() => {
  fetchBlockers()
  fetchLogs()
  fetchBaseData()
})
</script>

<style scoped>
.view-hero-bar {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
}

.hero-tag-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.hero-title {
  font-size: 22px;
  font-weight: 600;
  color: var(--text-main);
  letter-spacing: -0.01em;
}

.hero-desc {
  font-size: 13px;
  color: var(--text-muted);
  margin-top: 4px;
}

.grid-top {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

@media (min-width: 1080px) {
  .grid-top {
    grid-template-columns: 1fr 1fr;
  }
}

.left-col {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.right-col {
  height: 100%;
}

.detail-drawer {
  max-width: 640px;
}

.modal-form {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.form-row {
  display: flex;
  gap: 14px;
}

.flex-1 { flex: 1; }

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 18px;
  border-top: 1px solid var(--border-color);
  padding-top: 14px;
}

.detail-section {
  margin-bottom: 16px;
}

.detail-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main);
  margin-bottom: 6px;
}

.detail-value {
  font-size: 13px;
  color: var(--text-muted);
}

.detail-box {
  background: var(--bg-subtle);
  border: 1px solid var(--border-color);
  padding: 10px 14px;
  border-radius: 6px;
  font-size: 13px;
  line-height: 1.6;
  white-space: pre-wrap;
  color: var(--text-main);
}

.blocker-box {
  border-left: 3px solid var(--danger);
  background: var(--danger-bg);
}

.version-timeline {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.ver-item {
  background: var(--bg-subtle);
  padding: 10px 12px;
  border-radius: 6px;
  border: 1px solid var(--border-color);
}

.ver-head {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
}

.ver-time {
  color: var(--text-muted);
  flex: 1;
}

.ver-summary {
  font-size: 12px;
  color: var(--text-main);
  margin-top: 4px;
}

.comments-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.comment-item {
  background: var(--bg-subtle);
  border: 1px solid var(--border-color);
  padding: 10px 12px;
  border-radius: 6px;
}

.comment-head {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  margin-bottom: 4px;
}

.comment-author {
  color: var(--text-main);
}

.comment-date {
  color: var(--text-secondary);
}

.comment-text {
  font-size: 13px;
  color: var(--text-main);
}

.star-selector {
  display: flex;
  justify-content: center;
  gap: 8px;
}

.star-btn {
  font-size: 28px;
  color: #DEE0E3;
  cursor: pointer;
  transition: color 0.15s;
}

.star-btn.active {
  color: #FF7D00;
}

.empty-hint {
  text-align: center;
  padding: 16px;
  font-size: 12px;
  color: var(--text-secondary);
}
</style>
