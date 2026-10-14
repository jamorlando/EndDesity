<template>
  <div class="projects-view">
    <!-- 头部栏 (飞书 / TAPD 现代风格) -->
    <div class="view-hero-bar">
      <div>
        <div class="hero-tag-row">
          <span class="badge badge-primary">项目交付中枢</span>
          <span class="text-secondary" style="font-size: 12px;">敏捷交付与里程碑追踪</span>
        </div>
        <h1 class="hero-title">企业研发项目协同管理</h1>
        <p class="hero-desc">跨团队业务研发全周期交付 · 资源投入归属 · 点击项目卡片可下钻查看成员与交付详情</p>
      </div>
      <div class="hero-actions">
        <button v-if="authStore.isLeader" @click="showCreateModal = true" class="btn btn-primary" style="margin-right: 8px;">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
          </svg>
          创建新项目
        </button>
        <button @click="fetchProjects" class="btn btn-secondary">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="23 4 23 10 17 10"/>
            <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
          </svg>
          刷新项目
        </button>
      </div>
    </div>

    <!-- 项目卡片网格 (支持点击卡片穿透下钻) -->
    <div class="projects-grid">
      <div 
        v-for="p in projects" 
        :key="p.id" 
        class="project-card glass-card clickable-card"
        @click="openProjectDetail(p.id)"
      >
        <div class="proj-head">
          <span class="proj-code">{{ p.code }}</span>
          <span :class="statusBadge(p.status)">{{ statusText(p.status) }}</span>
        </div>
        <h3 class="proj-name">{{ p.name }}</h3>
        <p class="proj-desc">{{ p.description || '暂无项目详细背景介绍' }}</p>

        <div class="proj-meta">
          <div class="meta-item">
            <span class="meta-label">项目主管：</span>
            <strong class="text-main">{{ p.manager_name || '未指定' }}</strong>
          </div>
          <div class="meta-item">
            <span class="meta-label">责任团队：</span>
            <strong class="text-main">{{ p.team_name || '核心研发团队' }}</strong>
          </div>
          <div class="meta-item">
            <span class="meta-label">交付周期：</span>
            <span>{{ p.start_date }} ~ {{ p.end_date }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">参与成员：</span>
            <strong class="text-main" style="color: var(--primary);">{{ p.member_count }} 人</strong>
          </div>
        </div>

        <div class="card-action-hint">
          <span>点击查看项目编制与成员交付详情</span>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="9 18 15 12 9 6"/>
          </svg>
        </div>
      </div>
    </div>

    <!-- 项目详情与协同成员弹窗 (Project Detail Drawer/Modal) -->
    <div v-if="showDetailModal && currentProject" class="modal-backdrop" @click.self="showDetailModal = false">
      <div class="modal-card detail-modal-card">
        <div class="modal-header">
          <div class="modal-title-box">
            <span class="modal-title">{{ currentProject.name }}</span>
            <span class="proj-code">{{ currentProject.code }}</span>
            <span :class="statusBadge(currentProject.status)">{{ statusText(currentProject.status) }}</span>
          </div>
          <button @click="showDetailModal = false" class="btn-close">×</button>
        </div>

        <div class="project-detail-body">
          <div class="detail-block">
            <div class="block-title">项目目标与背景说明</div>
            <div class="desc-box">
              {{ currentProject.description || '负责核心技术架构演进与业务能力高可用交付。' }}
            </div>
          </div>

          <div class="detail-block">
            <div class="block-title">交付关键里程碑信息</div>
            <div class="info-grid-2">
              <div class="info-item">
                <span class="info-label">归属责任团队：</span>
                <strong class="text-main">{{ currentProject.team_name || '研发团队' }}</strong>
              </div>
              <div class="info-item">
                <span class="info-label">项目负责人 (PM)：</span>
                <strong class="text-main">{{ currentProject.manager_name || '待指定' }}</strong>
              </div>
              <div class="info-item">
                <span class="info-label">启动日期：</span>
                <span>{{ currentProject.start_date || '2026-09-01' }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">要求结项日期：</span>
                <span>{{ currentProject.end_date || '2026-12-31' }}</span>
              </div>
            </div>
          </div>

          <!-- 参与项目研发成员花名册 -->
          <div class="detail-block">
            <div class="block-head-row">
              <div class="block-title">跨团队参与成员 ({{ currentProject.members?.length || 0 }} 人)</div>
              <span class="text-secondary" style="font-size: 12px;">矩阵式项目制协同</span>
            </div>

            <div class="members-grid">
              <div v-for="m in currentProject.members" :key="m.user_id || m.id" class="member-card">
                <div class="avatar-box member-avatar">
                  {{ (m.real_name || m.username).slice(0, 1) }}
                </div>
                <div class="member-meta">
                  <div class="m-name-row">
                    <strong class="m-real-name">{{ m.real_name }}</strong>
                    <span class="badge badge-primary">{{ m.project_role || 'DEV' }}</span>
                  </div>
                  <div class="m-username">账号：{{ m.username }}</div>
                  <div class="m-contact">
                    <span v-if="m.email">{{ m.email }}</span>
                    <span v-if="m.phone"> · {{ m.phone }}</span>
                  </div>
                </div>
              </div>
              <div v-if="!currentProject.members?.length" class="empty-hint" style="grid-column: 1 / -1;">
                暂未指派固定项目矩阵成员，由归属团队全员攻坚
              </div>
            </div>
          </div>

          <!-- 业务联动 -->
          <div class="detail-block">
            <div class="block-title">跨模块协同快捷入口</div>
            <div class="nav-shortcuts">
              <button @click="navigateTo('/bi')" class="btn btn-secondary btn-sm shortcut-btn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                  <polyline points="14 2 14 8 20 8"/>
                </svg>
                前往工作台提交项目日志
              </button>
              <button @click="navigateTo('/zhi')" class="btn btn-secondary btn-sm shortcut-btn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                  <line x1="3" y1="9" x2="21" y2="9"/>
                </svg>
                参与项目 Sprint 复盘
              </button>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button @click="showDetailModal = false" class="btn btn-secondary">关闭面板</button>
        </div>
      </div>
    </div>

    <!-- 创建项目 Modal -->
    <div v-if="showCreateModal" class="modal-backdrop" @click.self="showCreateModal = false">
      <div class="modal-card">
        <div class="modal-header">
          <div class="modal-title">创建新项目</div>
          <button @click="showCreateModal = false" class="btn-close">×</button>
        </div>
        <form @submit.prevent="submitCreate" class="modal-form">
          <div class="form-group">
            <label class="form-label">项目名称</label>
            <input v-model="form.name" class="form-input" placeholder="例如：新一代高并发交易清算平台" required />
          </div>
          <div class="form-group">
            <label class="form-label">项目唯一编码</label>
            <input v-model="form.code" class="form-input" placeholder="例如：PROJ_TRADE_CORE" required />
          </div>
          <div class="form-group">
            <label class="form-label">主责归属团队</label>
            <select v-model="form.team_id" class="form-select" required>
              <option v-for="t in teams" :key="t.id" :value="t.id">{{ t.name }}</option>
            </select>
          </div>
          <div class="form-row">
            <div class="form-group flex-1">
              <label class="form-label">启动日期</label>
              <input v-model="form.start_date" type="date" class="form-input" />
            </div>
            <div class="form-group flex-1">
              <label class="form-label">结项日期</label>
              <input v-model="form.end_date" type="date" class="form-input" />
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">项目描述与背景</label>
            <textarea v-model="form.description" class="form-textarea" rows="3"></textarea>
          </div>
          <div class="modal-footer">
            <button type="button" @click="showCreateModal = false" class="btn btn-secondary">取消</button>
            <button type="submit" class="btn btn-primary">确认创建</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'
import { getProjectsApi, getProjectDetailApi, createProjectApi } from '../../api/projects'
import { getTeamsApi } from '../../api/teams'

const router = useRouter()
const authStore = useAuthStore()

const projects = ref([])
const teams = ref([])

const showDetailModal = ref(false)
const currentProject = ref(null)

const showCreateModal = ref(false)
const form = reactive({
  name: '',
  code: '',
  team_id: 1,
  start_date: '2026-09-01',
  end_date: '2026-12-31',
  description: ''
})

const statusText = (s) => {
  const map = {
    PLANNING: '规划中',
    IN_PROGRESS: '研发进行中',
    SUSPENDED: '已挂起',
    COMPLETED: '已完结'
  }
  return map[s] || s
}

const statusBadge = (s) => {
  if (s === 'IN_PROGRESS') return 'badge badge-success'
  if (s === 'COMPLETED') return 'badge badge-neutral'
  return 'badge badge-warning'
}

const fetchProjects = async () => {
  try {
    const res = await getProjectsApi()
    projects.value = res || []
  } catch (e) {
    console.error(e)
  }
}

const fetchTeams = async () => {
  try {
    const res = await getTeamsApi()
    teams.value = res || []
  } catch (e) {
    console.error(e)
  }
}

const openProjectDetail = async (projectId) => {
  try {
    const res = await getProjectDetailApi(projectId)
    currentProject.value = res
    showDetailModal.value = true
  } catch (e) {
    alert('获取项目详情失败：' + (e.message || '网络异常'))
  }
}

const submitCreate = async () => {
  try {
    await createProjectApi(form)
    showCreateModal.value = false
    fetchProjects()
  } catch (e) {
    alert(e.message)
  }
}

const navigateTo = (path) => {
  showDetailModal.value = false
  router.push(path)
}

onMounted(() => {
  fetchProjects()
  fetchTeams()
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

.projects-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

@media (min-width: 768px) {
  .projects-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1200px) {
  .projects-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

.project-card {
  padding: 20px;
  display: flex;
  flex-direction: column;
}

.clickable-card {
  cursor: pointer;
  transition: all 0.2s ease;
}

.clickable-card:hover {
  transform: translateY(-2px);
  border-color: var(--primary);
  box-shadow: 0 6px 20px rgba(51, 112, 255, 0.08);
}

.proj-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.proj-code {
  font-family: var(--font-mono);
  font-size: 11px;
  background: var(--bg-subtle);
  border: 1px solid var(--border-color);
  padding: 2px 8px;
  border-radius: 4px;
  color: var(--primary);
  font-weight: 600;
}

.proj-name {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-main);
  margin-bottom: 8px;
}

.proj-desc {
  font-size: 13px;
  color: var(--text-muted);
  line-height: 1.5;
  flex: 1;
  margin-bottom: 16px;
}

.proj-meta {
  border-top: 1px solid var(--border-light);
  padding-top: 12px;
  font-size: 12px;
  color: var(--text-muted);
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.meta-item {
  display: flex;
  justify-content: space-between;
}

.meta-label {
  color: var(--text-secondary);
}

.text-main {
  color: var(--text-main);
}

.card-action-hint {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-top: 1px dashed var(--border-light);
  margin-top: 12px;
  padding-top: 8px;
  font-size: 12px;
  color: var(--primary);
  font-weight: 500;
}

/* 详情弹窗 */
.detail-modal-card {
  max-width: 680px;
}

.modal-title-box {
  display: flex;
  align-items: center;
  gap: 8px;
}

.modal-title {
  font-size: 17px;
  font-weight: 600;
  color: var(--text-main);
}

.project-detail-body {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin: 16px 0;
}

.detail-block {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.block-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main);
}

.desc-box {
  background: var(--bg-subtle);
  border: 1px solid var(--border-color);
  padding: 10px 14px;
  border-radius: 6px;
  font-size: 13px;
  line-height: 1.6;
  color: var(--text-main);
}

.info-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 12px 16px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
}

.info-label {
  color: var(--text-secondary);
}

.block-head-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.members-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 10px;
}

@media (min-width: 600px) {
  .members-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.member-card {
  display: flex;
  align-items: center;
  gap: 12px;
  background: var(--bg-subtle);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 10px 14px;
}

.avatar-box {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 14px;
  flex-shrink: 0;
}

.member-avatar {
  background: #E8F3FF;
  color: var(--primary);
  border: 1px solid rgba(51, 112, 255, 0.2);
}

.member-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  overflow: hidden;
}

.m-name-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.m-real-name {
  font-size: 13px;
  color: var(--text-main);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.m-username {
  font-size: 11px;
  color: var(--text-secondary);
  font-family: var(--font-mono);
}

.m-contact {
  font-size: 11px;
  color: var(--text-muted);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.nav-shortcuts {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.shortcut-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
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

.empty-hint {
  text-align: center;
  padding: 16px;
  font-size: 12px;
  color: var(--text-secondary);
}
</style>
