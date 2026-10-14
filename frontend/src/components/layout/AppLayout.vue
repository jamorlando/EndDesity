<template>
  <div class="app-wrapper">
    <!-- 顶栏导航 (飞书 / TAPD 极简白底现代风格) -->
    <header class="app-header">
      <div class="header-inner">
        <!-- 品牌标识 -->
        <div class="brand-area" @click="router.push('/bi')">
          <div class="brand-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
            </svg>
          </div>
          <div class="brand-text-col">
            <div class="brand-title">
              团队工作日志与智能复盘系统
              <span class="badge badge-primary" style="font-size: 11px; margin-left: 8px; font-weight: 500;">v1.0 生产级</span>
            </div>
            <div class="brand-sub">ENTERPRISE DEV-LOG & AGILE RETROSPECTIVE PLATFORM</div>
          </div>
        </div>

        <!-- 现代化中心导航条 -->
        <nav class="nav-tabs">
          <router-link to="/bi" class="nav-tab-btn" active-class="active">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
              <polyline points="14 2 14 8 20 8"/>
              <line x1="16" y1="13" x2="8" y2="13"/>
              <line x1="16" y1="17" x2="8" y2="17"/>
              <polyline points="10 9 9 9 8 9"/>
            </svg>
            <span>工作日志</span>
          </router-link>

          <router-link to="/zhi" class="nav-tab-btn" active-class="active">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
              <line x1="3" y1="9" x2="21" y2="9"/>
              <line x1="9" y1="21" x2="9" y2="9"/>
            </svg>
            <span>敏捷复盘</span>
          </router-link>

          <router-link to="/mo" class="nav-tab-btn" active-class="active">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="20" x2="18" y2="10"/>
              <line x1="12" y1="20" x2="12" y2="4"/>
              <line x1="6" y1="20" x2="6" y2="14"/>
            </svg>
            <span>效能大屏</span>
          </router-link>

          <router-link to="/yan" class="nav-tab-btn" active-class="active">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="3" width="20" height="14" rx="2" ry="2"/>
              <line x1="8" y1="21" x2="16" y2="21"/>
              <line x1="12" y1="17" x2="12" y2="21"/>
            </svg>
            <span>AI 网关</span>
          </router-link>

          <span class="nav-divider"></span>

          <router-link to="/projects" class="nav-tab-btn" active-class="active">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
            </svg>
            <span>项目协同</span>
          </router-link>

          <router-link to="/teams" class="nav-tab-btn" active-class="active">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
              <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
              <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
            </svg>
            <span>团队组织</span>
          </router-link>
        </nav>

        <!-- 用户信息与退出操作 -->
        <div class="user-area">
          <div class="user-profile">
            <div class="avatar-circle">
              {{ (authStore.user?.real_name || '研').slice(0, 1) }}
            </div>
            <div class="user-meta">
              <span class="user-name">{{ authStore.user?.real_name || '研发骨干' }}</span>
              <span class="user-role-tag" :class="roleTagClass">{{ userRoleName }}</span>
            </div>
          </div>

          <button @click="handleLogout" class="btn btn-secondary btn-sm" title="退出系统">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
              <polyline points="16 17 21 12 16 7"></polyline>
              <line x1="21" y1="12" x2="9" y2="12"></line>
            </svg>
            退出
          </button>
        </div>
      </div>
    </header>

    <!-- 视图主工作区 -->
    <main class="main-container">
      <router-view />
    </main>

    <!-- 页脚 -->
    <footer class="app-footer">
      <div class="footer-inner">
        <div>团队工作日志与智能复盘管理系统 · 基于 Python FastAPI + Vue3 现代化工程架构</div>
        <div class="footer-sub">
          标准化敏捷度量 · Agentic Tooling 扩展支持 · 纯前端零外网 CDN 稳定架构
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

onMounted(() => {
  authStore.fetchProfile()
})

const userRoleName = computed(() => {
  const role = authStore.user?.role
  if (role === 'SUPER_ADMIN') return '超级管理员'
  if (role === 'TEAM_LEADER') return '团队主管'
  return '研发工程师'
})

const roleTagClass = computed(() => {
  const role = authStore.user?.role
  if (role === 'SUPER_ADMIN') return 'role-admin'
  if (role === 'TEAM_LEADER') return 'role-leader'
  return 'role-member'
})

const handleLogout = async () => {
  await authStore.logout()
  router.push('/login')
}
</script>

<style scoped>
.app-wrapper {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: var(--bg-primary);
}

.brand-area {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
}

.brand-icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: linear-gradient(135deg, #3370FF 0%, #165DFF 100%);
  color: #FFFFFF;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 6px rgba(51, 112, 255, 0.25);
}

.brand-text-col {
  display: flex;
  flex-direction: column;
}

.brand-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-main);
  display: flex;
  align-items: center;
}

.brand-sub {
  font-size: 10px;
  letter-spacing: 0.05em;
  color: var(--text-secondary);
  margin-top: 1px;
}

.nav-divider {
  display: inline-block;
  width: 1px;
  height: 16px;
  background: var(--border-color);
  margin: 0 4px;
}

.user-area {
  display: flex;
  align-items: center;
  gap: 16px;
}

.user-profile {
  display: flex;
  align-items: center;
  gap: 8px;
}

.avatar-circle {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: #E8F3FF;
  color: var(--primary);
  font-weight: 600;
  font-size: 13px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid rgba(51, 112, 255, 0.2);
}

.user-meta {
  display: flex;
  flex-direction: column;
  line-height: 1.2;
}

.user-name {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main);
}

.user-role-tag {
  font-size: 10px;
  font-weight: 500;
  padding: 1px 4px;
  border-radius: 3px;
  margin-top: 2px;
  width: fit-content;
}

.role-admin {
  background: #FFECE8;
  color: #F53F3F;
}

.role-leader {
  background: #E8F3FF;
  color: #3370FF;
}

.role-member {
  background: #F2F3F5;
  color: #646A73;
}

.app-footer {
  margin-top: auto;
  padding: 20px 24px;
  border-top: 1px solid var(--border-color);
  background: #FFFFFF;
  font-size: 12px;
  color: var(--text-muted);
  text-align: center;
}

.footer-sub {
  font-size: 11px;
  color: var(--text-secondary);
  margin-top: 4px;
}
</style>
