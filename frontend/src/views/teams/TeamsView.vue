<template>
  <div class="teams-view">
    <!-- 头部栏 (飞书 / TAPD 现代组织架构中枢) -->
    <div class="view-hero-bar">
      <div>
        <div class="hero-tag-row">
          <span class="badge badge-primary">组织架构中枢</span>
          <span class="text-secondary" style="font-size: 12px;">在编运行与角色矩阵</span>
        </div>
        <h1 class="hero-title">研发团队与效能方阵</h1>
        <p class="hero-desc">高内聚业务领域划分 · 主管责任制 · 点击卡片深入查看在编研发骨干与成员花名册</p>
      </div>
      <div class="hero-actions">
        <button v-if="authStore.isRoot" @click="openCreateTeamModal" class="btn btn-primary" style="margin-right: 8px;">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
          </svg>
          新建研发团队
        </button>
        <button @click="fetchTeams" class="btn btn-secondary">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="23 4 23 10 17 10"/>
            <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
          </svg>
          刷新团队架构
        </button>
      </div>
    </div>

    <!-- 团队卡片网格 (支持点击卡片穿透下钻) -->
    <div class="teams-grid">
      <div 
        v-for="t in teams" 
        :key="t.id" 
        class="team-card glass-card clickable-card"
        @click="openTeamDetail(t.id)"
      >
        <div class="team-head">
          <span class="team-code">{{ t.code }}</span>
          <span class="badge badge-success">{{ t.is_active ? '在编运行中' : '已归档' }}</span>
        </div>
        <h3 class="team-name">{{ t.name }}</h3>
        <p class="team-desc">{{ t.description || '负责核心技术底座与工程交付' }}</p>

        <div class="team-meta">
          <div class="meta-row">
            <span class="meta-label">团队主管：</span>
            <strong class="text-main">{{ t.leader_name || '待指定' }}</strong>
          </div>
          <div class="meta-row">
            <span class="meta-label">在编骨干：</span>
            <strong class="text-main" style="color: var(--primary);">{{ t.member_count }} 人</strong>
          </div>
          <div class="meta-row">
            <span class="meta-label">创建时间：</span>
            <span>{{ t.created_at?.slice(0, 10) }}</span>
          </div>
        </div>

        <div class="card-action-hint">
          <span>点击查看团队成员与编制详情</span>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="9 18 15 12 9 6"/>
          </svg>
        </div>
      </div>
    </div>

    <!-- 团队详情与编制花名册抽屉/弹窗 (Detail Drawer) -->
    <div v-if="showDetailModal && currentTeam" class="modal-backdrop" @click.self="showDetailModal = false">
      <div class="modal-card detail-modal-card">
        <!-- 弹窗顶栏 -->
        <div class="modal-header">
          <div class="modal-title-box">
            <span class="modal-title">{{ currentTeam.name }}</span>
            <span class="team-code">{{ currentTeam.code }}</span>
            <span class="badge badge-success">在编运行中</span>
          </div>
          <button @click="showDetailModal = false" class="btn-close">×</button>
        </div>

        <!-- 团队基本信息与定位 -->
        <div class="team-detail-body">
          <div class="detail-block">
            <div class="block-title">团队业务定位与职责</div>
            <div class="desc-box">
              {{ currentTeam.description || '负责相关技术栈的架构选型、日常业务研发与高可用保障' }}
            </div>
          </div>

          <!-- 主管卡片 -->
          <div class="detail-block">
            <div class="block-title">团队责任主管</div>
            <div class="leader-card">
              <div class="avatar-box leader-avatar">
                {{ (currentTeam.leader_name || '主').slice(0, 1) }}
              </div>
              <div class="leader-info">
                <div class="leader-name">
                  <span>{{ currentTeam.leader_name || '待指定' }}</span>
                  <span class="badge badge-primary">主管责任人</span>
                </div>
                <div class="leader-sub">负责本团队成员的日常工时审核、卡点攻坚督办与 KISS 敏捷复盘调度</div>
              </div>
            </div>
          </div>

          <!-- 在编研发骨干成员花名册 -->
          <div class="detail-block">
            <div class="block-head-row">
              <div class="block-title">在编研发骨干成员 ({{ currentTeam.members?.length || 0 }} 人)</div>
              <span class="text-secondary" style="font-size: 12px;">统一鉴权体系</span>
            </div>

            <div class="members-grid">
              <div v-for="m in currentTeam.members" :key="m.id" class="member-card">
                <div class="avatar-box member-avatar">
                  {{ (m.real_name || m.username).slice(0, 1) }}
                </div>
                <div class="member-meta">
                  <div class="m-name-row">
                    <strong class="m-real-name">{{ m.real_name }}</strong>
                    <span :class="getRoleBadgeClass(m.role)">{{ getRoleName(m.role) }}</span>
                  </div>
                  <div class="m-username">账号：{{ m.username }}</div>
                  <div class="m-contact">
                    <span v-if="m.email">{{ m.email }}</span>
                    <span v-if="m.phone"> · {{ m.phone }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- 研发业务快捷联动操作条 -->
          <div class="detail-block">
            <div class="block-title">跨模块业务快捷联动</div>
            <div class="nav-shortcuts">
              <button @click="navigateTo('/bi')" class="btn btn-secondary btn-sm shortcut-btn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                  <polyline points="14 2 14 8 20 8"/>
                </svg>
                查看该团队工作日志流水
              </button>
              <button @click="navigateTo('/zhi')" class="btn btn-secondary btn-sm shortcut-btn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                  <line x1="3" y1="9" x2="21" y2="9"/>
                </svg>
                发起 KISS 敏捷复盘
              </button>
              <button @click="navigateTo('/mo')" class="btn btn-secondary btn-sm shortcut-btn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <line x1="18" y1="20" x2="18" y2="10"/>
                  <line x1="12" y1="20" x2="12" y2="4"/>
                  <line x1="6" y1="20" x2="6" y2="14"/>
                </svg>
                效能度量与工时燃尽全景
              </button>
            </div>
          </div>
        </div>

        <!-- 底部关闭操作 -->
        <div class="modal-footer">
          <button @click="showDetailModal = false" class="btn btn-secondary">关闭面板</button>
        </div>
      </div>
    </div>

    <!-- 创建新团队 Modal (管理员特权) -->
    <div v-if="showCreateModal" class="modal-backdrop" @click.self="showCreateModal = false">
      <div class="modal-card" style="max-width: 520px;">
        <div class="modal-header">
          <div class="modal-title">新建研发团队方阵</div>
          <button @click="showCreateModal = false" class="btn-close">×</button>
        </div>
        <form @submit.prevent="submitCreateTeam" class="modal-form">
          <div class="form-group">
            <label class="form-label">团队名称</label>
            <input v-model="createForm.name" class="form-input" placeholder="例如：云原生与安全攻防组" required />
          </div>
          <div class="form-group">
            <label class="form-label">团队唯一编码 (全大写下划线)</label>
            <input v-model="createForm.code" class="form-input" placeholder="例如：TEAM_SECURITY" required />
          </div>
          <div class="form-group">
            <label class="form-label">团队职责与业务范围描述</label>
            <textarea v-model="createForm.description" class="form-textarea" rows="3" placeholder="简述该团队核心负责的业务与技术领域..."></textarea>
          </div>
          <div class="modal-footer">
            <button type="button" @click="showCreateModal = false" class="btn btn-secondary">取消</button>
            <button type="submit" class="btn btn-primary" :disabled="submitting">
              {{ submitting ? '正在创建...' : '确认创建团队' }}
            </button>
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
import { getTeamsApi, getTeamDetailApi, createTeamApi } from '../../api/teams'

const router = useRouter()
const authStore = useAuthStore()

const teams = ref([])
const showDetailModal = ref(false)
const currentTeam = ref(null)

const showCreateModal = ref(false)
const submitting = ref(false)
const createForm = reactive({
  name: '',
  code: '',
  description: '',
  leader_id: null
})

const fetchTeams = async () => {
  try {
    const res = await getTeamsApi()
    teams.value = res || []
  } catch (e) {
    console.error(e)
  }
}

const openTeamDetail = async (teamId) => {
  try {
    const res = await getTeamDetailApi(teamId)
    currentTeam.value = res
    showDetailModal.value = true
  } catch (e) {
    alert('获取团队详情失败：' + (e.message || '网络异常'))
  }
}

const openCreateTeamModal = () => {
  createForm.name = ''
  createForm.code = ''
  createForm.description = ''
  showCreateModal.value = true
}

const submitCreateTeam = async () => {
  submitting.value = true
  try {
    await createTeamApi(createForm)
    showCreateModal.value = false
    await fetchTeams()
  } catch (e) {
    alert(e.message)
  } finally {
    submitting.value = false
  }
}

const getRoleName = (role) => {
  if (role === 'SUPER_ADMIN') return '超级管理员'
  if (role === 'TEAM_LEADER') return '团队主管'
  return '研发骨干'
}

const getRoleBadgeClass = (role) => {
  if (role === 'SUPER_ADMIN') return 'badge badge-danger'
  if (role === 'TEAM_LEADER') return 'badge badge-primary'
  return 'badge badge-neutral'
}

const navigateTo = (path) => {
  showDetailModal.value = false
  router.push(path)
}

onMounted(() => {
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

.teams-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

@media (min-width: 768px) {
  .teams-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1200px) {
  .teams-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

.team-card {
  padding: 22px;
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

.team-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.team-code {
  font-family: var(--font-mono);
  font-size: 11px;
  background: var(--bg-subtle);
  border: 1px solid var(--border-color);
  padding: 2px 8px;
  border-radius: 4px;
  color: var(--primary);
  font-weight: 600;
}

.team-name {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-main);
  margin-bottom: 8px;
}

.team-desc {
  font-size: 13px;
  color: var(--text-muted);
  line-height: 1.5;
  flex: 1;
  margin-bottom: 16px;
}

.team-meta {
  border-top: 1px solid var(--border-light);
  padding-top: 14px;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.meta-row {
  display: flex;
  justify-content: space-between;
  color: var(--text-muted);
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

/* 详情弹窗样式 */
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

.team-detail-body {
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

.block-head-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
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

/* 主管卡片 */
.leader-card {
  display: flex;
  align-items: center;
  gap: 12px;
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  padding: 12px 16px;
  border-radius: 8px;
}

.avatar-box {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 15px;
  flex-shrink: 0;
}

.leader-avatar {
  background: var(--primary-light);
  color: var(--primary);
  border: 1px solid rgba(51, 112, 255, 0.25);
}

.leader-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.leader-name {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 600;
  color: var(--text-main);
}

.leader-sub {
  font-size: 12px;
  color: var(--text-secondary);
}

/* 成员网格 */
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
  transition: border-color 0.15s;
}

.member-card:hover {
  border-color: #CFD5DE;
  background: #FFFFFF;
}

.member-avatar {
  background: #F0F2F5;
  color: var(--text-main);
  border: 1px solid var(--border-color);
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

/* 快捷联动条 */
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
</style>
