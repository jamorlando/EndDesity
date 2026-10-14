<template>
  <div class="zhi-view">
    <!-- 头部栏 (飞书 / TAPD 现代敏捷复盘驾驶舱) -->
    <div class="view-hero-bar">
      <div>
        <div class="hero-tag-row">
          <span class="badge badge-primary">敏捷效能中枢</span>
          <span class="text-secondary" style="font-size: 12px;">KISS / GRAI 体系支持</span>
        </div>
        <h1 class="hero-title">KISS 敏捷复盘驾驶舱</h1>
        <p class="hero-desc">KISS 敏捷方法论四象限 · 高频卡点词频归集 · 改进行动军令状闭环</p>
      </div>
      <div class="hero-actions">
        <button @click="showCreateModal = true" class="btn btn-primary">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
          </svg>
          发起智能复盘任务
        </button>
      </div>
    </div>

    <!-- 顶栏核心统计卡片组 -->
    <div class="retro-stats-row">
      <div class="stat-pill glass-card">
        <div class="pill-label">累计复盘报告</div>
        <div class="pill-val">{{ reports.length }} <span class="pill-unit">篇</span></div>
      </div>
      <div class="stat-pill glass-card">
        <div class="pill-label">待办改进项 (TODO)</div>
        <div class="pill-val" style="color: var(--warning);">{{ countByStatus('TODO') }} <span class="pill-unit">项</span></div>
      </div>
      <div class="stat-pill glass-card">
        <div class="pill-label">推进攻坚中 (DOING)</div>
        <div class="pill-val" style="color: var(--primary);">{{ countByStatus('DOING') }} <span class="pill-unit">项</span></div>
      </div>
      <div class="stat-pill glass-card">
        <div class="pill-label">已成功闭环 (DONE)</div>
        <div class="pill-val" style="color: var(--success);">{{ countByStatus('DONE') }} <span class="pill-unit">项</span></div>
      </div>
    </div>

    <!-- 报告选择与综述卡片 -->
    <div class="glass-card" style="margin-bottom: 20px;">
      <div class="card-header">
        <div class="card-title">
          <span class="accent-bar"></span>
          <span>当前复盘课题：{{ activeReport ? activeReport.title : '请选择复盘任务' }}</span>
        </div>
        <div class="report-select-wrap">
          <select v-model="selectedReportId" @change="loadReportDetail" class="form-select" style="padding: 6px 12px; font-size: 13px; width: auto; min-width: 280px;">
            <option v-for="r in reports" :key="r.id" :value="r.id">{{ r.title }} ({{ r.start_date }} ~ {{ r.end_date }})</option>
          </select>
        </div>
      </div>
      <div v-if="activeReport" class="retro-summary-box">
        <div class="summary-tag">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/>
            <polyline points="3.27 6.96 12 12.01 20.73 6.96"/>
            <line x1="12" y1="22.08" x2="12" y2="12"/>
          </svg>
          <span>AI 研发中枢深度洞察综述</span>
        </div>
        <p class="summary-text">{{ activeReport.final_content || activeReport.ai_draft }}</p>
      </div>
    </div>

    <!-- KISS 四象限 2x2 敏捷复盘矩阵 -->
    <div style="margin-bottom: 20px;">
      <KissQuadrantScreen :kiss-data="kissData" />
    </div>

    <!-- 高频卡点词频列表 + ActionItemsTableCard 复盘决议改进清单 -->
    <div class="retro-bottom-grid">
      <!-- 高频研发阻碍词频分布卡片 -->
      <div class="glass-card">
        <div class="card-header">
          <div class="card-title">
            <span class="accent-bar"></span>
            <span>高频研发阻碍词频分布云图</span>
          </div>
        </div>
        <div class="cloud-tags">
          <span 
            v-for="(bw, idx) in activeReport?.blocker_keywords || []" 
            :key="idx" 
            class="cloud-tag"
            :class="`sev-${bw.severity?.toLowerCase()}`"
          >
            {{ bw.word }} ({{ bw.count }}次)
          </span>
          <span v-if="!activeReport?.blocker_keywords?.length" class="empty-hint">暂无提取出的卡点高频词</span>
        </div>
      </div>

      <!-- ActionItemsTableCard 复盘决议改进待办军令状清单 -->
      <div>
        <ActionItemsTableCard 
          :items="actionItems"
          @refresh="fetchActionItems"
          @update-status="updateStatus"
          @open-complete="openCompleteModal"
        />
      </div>
    </div>

    <!-- 发起智能复盘 Modal -->
    <div v-if="showCreateModal" class="modal-backdrop">
      <div class="modal-card">
        <div class="modal-header">
          <div class="modal-title">发起团队智能复盘</div>
          <button @click="showCreateModal = false" class="btn-close">×</button>
        </div>

        <form @submit.prevent="submitRetro" class="modal-form">
          <div class="form-group">
            <label class="form-label">复盘报告标题</label>
            <input v-model="createForm.title" class="form-input" placeholder="例如：2026年9月上旬研发效能与架构攻坚复盘" required />
          </div>

          <div class="form-row">
            <div class="form-group flex-1">
              <label class="form-label">复盘周期起始日期</label>
              <input v-model="createForm.start_date" type="date" class="form-input" required />
            </div>
            <div class="form-group flex-1">
              <label class="form-label">复盘周期截止日期</label>
              <input v-model="createForm.end_date" type="date" class="form-input" required />
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">复盘方法论体系</label>
            <select v-model="createForm.template_id" class="form-select">
              <option :value="1">KISS 敏捷复盘矩阵 (Keep, Improve, Start, Stop)</option>
              <option :value="2">GRAI 目标与结果差距推演</option>
              <option :value="3">ORID 焦点讨论法则</option>
            </select>
          </div>

          <div class="tip-box">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/>
              <line x1="12" y1="16" x2="12" y2="12"/>
              <line x1="12" y1="8" x2="12.01" y2="8"/>
            </svg>
            <span>系统将自动调取周期内沉淀的工作日志、工时明细与攻坚卡点，驱动 AI 智能网关自动输出结构化 KISS 四象限洞察并生成改进行动项。</span>
          </div>

          <div class="modal-footer">
            <button type="button" @click="showCreateModal = false" class="btn btn-secondary">取消</button>
            <button type="submit" class="btn btn-primary" :disabled="creating">
              {{ creating ? 'AI 正在深度提炼洞察中...' : '开始提炼复盘报告' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- 完成行动项凭据 Modal -->
    <div v-if="showCompleteModal && completingAct" class="modal-backdrop">
      <div class="modal-card" style="max-width: 460px;">
        <div class="modal-header">
          <div class="modal-title">改进行动项验收与闭环</div>
          <button @click="showCompleteModal = false" class="btn-close">×</button>
        </div>
        <div class="form-group" style="margin-top: 14px;">
          <label class="form-label">交付成果凭据说明</label>
          <textarea v-model="completeResultText" class="form-textarea" rows="3" placeholder="简述该改进措施的落地实施成果（如：已合并MR、已重构连接池并压测无异常）..." required></textarea>
        </div>
        <div class="modal-footer">
          <button @click="showCompleteModal = false" class="btn btn-secondary">取消</button>
          <button @click="submitCompleteAct" class="btn btn-success">确认闭环</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import KissQuadrantScreen from '../../components/zhi/KissQuadrantScreen.vue'
import ActionItemsTableCard from '../../components/zhi/ActionItemsTableCard.vue'
import { 
  getReportsApi, getReportDetailApi, createReportApi,
  getActionItemsApi, updateActionItemApi 
} from '../../api/retrospectives'

const reports = ref([])
const selectedReportId = ref(null)
const activeReport = ref(null)
const actionItems = ref([])

const showCreateModal = ref(false)
const creating = ref(false)
const createForm = reactive({
  title: '2026年9月中旬团队研发效能与架构智能复盘',
  template_id: 1,
  start_date: '2026-09-01',
  end_date: '2026-09-14',
  scope_type: 'TEAM'
})

const showCompleteModal = ref(false)
const completingAct = ref(null)
const completeResultText = ref('')

const kissData = computed(() => {
  return activeReport.value?.kiss_structured_json || {
    keep: [],
    improve: [],
    start: [],
    stop: []
  }
})

const countByStatus = (status) => {
  return actionItems.value.filter(a => a.status === status).length
}

const fetchReports = async () => {
  try {
    const res = await getReportsApi({ page: 1, page_size: 20 })
    reports.value = res.items || []
    if (reports.value.length > 0 && !selectedReportId.value) {
      selectedReportId.value = reports.value[0].id
      loadReportDetail()
    }
  } catch (e) {
    console.error(e)
  }
}

const loadReportDetail = async () => {
  if (!selectedReportId.value) return
  try {
    const res = await getReportDetailApi(selectedReportId.value)
    activeReport.value = res
  } catch (e) {
    console.error(e)
  }
}

const fetchActionItems = async () => {
  try {
    const res = await getActionItemsApi()
    actionItems.value = res || []
  } catch (e) {
    console.error(e)
  }
}

const submitRetro = async () => {
  creating.value = true
  try {
    const res = await createReportApi(createForm)
    showCreateModal.value = false
    await fetchReports()
    selectedReportId.value = res.id
    await loadReportDetail()
    await fetchActionItems()
  } catch (e) {
    alert(e.message)
  } finally {
    creating.value = false
  }
}

const updateStatus = async (id, status, resultSummary = null) => {
  try {
    await updateActionItemApi(id, { status, result_summary: resultSummary })
    await fetchActionItems()
  } catch (e) {
    alert(e.message)
  }
}

const openCompleteModal = (act) => {
  completingAct.value = act
  completeResultText.value = '已严格依照工程规范通过自测与线上验证，确认闭环完成。'
  showCompleteModal.value = true
}

const submitCompleteAct = async () => {
  if (!completingAct.value) return
  await updateStatus(completingAct.value.id, 'DONE', completeResultText.value)
  showCompleteModal.value = false
}

onMounted(() => {
  fetchReports()
  fetchActionItems()
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

.retro-stats-row {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  margin-bottom: 20px;
}

@media (min-width: 768px) {
  .retro-stats-row {
    grid-template-columns: repeat(4, 1fr);
  }
}

.stat-pill {
  padding: 16px 20px;
}

.pill-label {
  font-size: 12px;
  color: var(--text-muted);
}

.pill-val {
  font-size: 26px;
  font-weight: 700;
  margin-top: 4px;
  color: var(--text-main);
}

.pill-unit {
  font-size: 13px;
  font-weight: normal;
  color: var(--text-muted);
  margin-left: 2px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 14px;
}

.card-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  font-weight: 600;
  color: var(--text-main);
}

.accent-bar {
  width: 3px;
  height: 14px;
  background: var(--primary);
  border-radius: 2px;
  display: inline-block;
}

.retro-summary-box {
  background: var(--bg-subtle);
  border-left: 3px solid var(--primary);
  padding: 14px 18px;
  border-radius: 0 6px 6px 0;
}

.summary-tag {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 600;
  color: var(--primary);
  margin-bottom: 6px;
}

.summary-text {
  font-size: 13px;
  line-height: 1.6;
  color: var(--text-main);
}

.retro-bottom-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

@media (min-width: 1024px) {
  .retro-bottom-grid {
    grid-template-columns: 0.85fr 1.15fr;
  }
}

.cloud-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  padding: 6px 0;
}

.cloud-tag {
  font-size: 12px;
  padding: 4px 10px;
  border-radius: 4px;
  background: var(--bg-subtle);
  border: 1px solid var(--border-color);
  color: var(--text-main);
}

.cloud-tag.sev-high {
  background: var(--danger-bg);
  color: var(--danger);
  border-color: var(--danger-border);
}

.cloud-tag.sev-medium {
  background: var(--warning-bg);
  color: var(--warning);
  border-color: var(--warning-border);
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
  margin-top: 16px;
  border-top: 1px solid var(--border-color);
  padding-top: 14px;
}

.tip-box {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  background: var(--primary-light);
  border: 1px solid rgba(51, 112, 255, 0.2);
  padding: 10px 12px;
  border-radius: 6px;
  font-size: 12px;
  color: var(--primary);
  line-height: 1.5;
}

.empty-hint {
  text-align: center;
  padding: 24px 0;
  color: var(--text-secondary);
  font-size: 12px;
}
</style>
