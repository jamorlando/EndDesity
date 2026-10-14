<template>
  <div class="login-wrapper">
    <div class="login-container">
      <div class="login-card">
        <!-- 品牌标识与主副标题 -->
        <div class="login-header">
          <div class="logo-box">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
            </svg>
          </div>
          <h1 class="login-title">团队工作日志与智能复盘系统</h1>
          <p class="login-desc">现代研发效能中枢 · 敏捷卡点治理 · AI 智能复盘</p>
        </div>

        <!-- 快速切换体验账号 (毕业答辩与演示首选用例) -->
        <div class="demo-accounts">
          <div class="demo-header">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/>
              <line x1="12" y1="16" x2="12" y2="12"/>
              <line x1="12" y1="8" x2="12.01" y2="8"/>
            </svg>
            <span>一键切换演示账号 (密码统设为 123456)</span>
          </div>
          <div class="demo-btns">
            <button 
              type="button" 
              @click="fillAccount('root', '123456')" 
              class="demo-btn"
              :class="{ active: form.username === 'root' }"
            >
              超管 (root)
            </button>
            <button 
              type="button" 
              @click="fillAccount('leader_zhang', '123456')" 
              class="demo-btn"
              :class="{ active: form.username === 'leader_zhang' }"
            >
              主管 (leader_zhang)
            </button>
            <button 
              type="button" 
              @click="fillAccount('dev_chen', '123456')" 
              class="demo-btn"
              :class="{ active: form.username === 'dev_chen' }"
            >
              研发 (dev_chen)
            </button>
          </div>
        </div>

        <!-- 登录核心表单 -->
        <form @submit.prevent="handleLogin" class="login-form">
          <div class="form-group">
            <label class="form-label">登录账号</label>
            <div class="input-prefix-box">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
              </svg>
              <input 
                v-model="form.username" 
                type="text" 
                class="modern-input" 
                placeholder="请输入用户名 (如 root / dev_chen)"
                required
              />
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">登录密码</label>
            <div class="input-prefix-box">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
              </svg>
              <input 
                v-model="form.password" 
                type="password" 
                class="modern-input" 
                placeholder="请输入密码"
                required
              />
            </div>
          </div>

          <div v-if="errorMessage" class="error-alert">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/>
              <line x1="12" y1="8" x2="12" y2="12"/>
              <line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            <span>{{ errorMessage }}</span>
          </div>

          <button type="submit" class="btn btn-primary login-btn" :disabled="loading">
            <span v-if="loading">正在验证身份...</span>
            <span v-else>立即登录工作台</span>
          </button>
        </form>

        <!-- 底部安全与架构说明 -->
        <div class="login-footer">
          <span>企业级生产标准：BCrypt 动态盐哈希 · JWT 鉴权防护 · 行级数据隔离</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const form = reactive({
  username: 'root',
  password: '123456'
})

const loading = ref(false)
const errorMessage = ref('')

const fillAccount = (username, password) => {
  form.username = username
  form.password = password
  errorMessage.value = ''
}

const handleLogin = async () => {
  loading.value = true
  errorMessage.value = ''
  try {
    await authStore.login(form.username, form.password)
    router.push('/bi')
  } catch (err) {
    errorMessage.value = err.message || '账号或密码不正确，请重试'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--bg-primary);
  position: relative;
  padding: 24px;
}

.login-container {
  width: 100%;
  max-width: 440px;
  position: relative;
  z-index: 10;
}

.login-card {
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  border-radius: 12px;
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.06);
  padding: 36px 32px;
}

.login-header {
  text-align: center;
  margin-bottom: 24px;
}

.logo-box {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  background: linear-gradient(135deg, #3370FF 0%, #165DFF 100%);
  color: #FFFFFF;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 16px;
  box-shadow: 0 4px 12px rgba(51, 112, 255, 0.28);
}

.login-title {
  font-size: 20px;
  font-weight: 600;
  color: var(--text-main);
  margin-bottom: 6px;
  letter-spacing: -0.01em;
}

.login-desc {
  font-size: 13px;
  color: var(--text-muted);
}

.demo-accounts {
  background: var(--bg-subtle);
  border: 1px solid #E5E6EB;
  border-radius: 8px;
  padding: 12px 14px;
  margin-bottom: 20px;
}

.demo-header {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 500;
  color: var(--text-muted);
  margin-bottom: 8px;
}

.demo-btns {
  display: flex;
  gap: 8px;
}

.demo-btn {
  flex: 1;
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  padding: 6px 8px;
  border-radius: 6px;
  font-size: 12px;
  color: var(--text-main);
  cursor: pointer;
  transition: all 0.15s;
}

.demo-btn:hover {
  border-color: var(--primary);
  color: var(--primary);
}

.demo-btn.active {
  background: var(--primary-light);
  border-color: var(--primary);
  color: var(--primary);
  font-weight: 600;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--text-main);
}

.input-prefix-box {
  position: relative;
  display: flex;
  align-items: center;
}

.input-prefix-box svg {
  position: absolute;
  left: 12px;
  color: var(--text-secondary);
  pointer-events: none;
}

.modern-input {
  width: 100%;
  padding: 9px 12px 9px 36px;
  font-size: 14px;
  font-family: var(--font-sans);
  color: var(--text-main);
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  outline: none;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.modern-input:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px rgba(51, 112, 255, 0.15);
}

.error-alert {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--danger-bg);
  border: 1px solid var(--danger-border);
  color: var(--danger);
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 12px;
}

.login-btn {
  width: 100%;
  padding: 10px;
  font-size: 14px;
  font-weight: 600;
  margin-top: 6px;
}

.login-footer {
  text-align: center;
  font-size: 11px;
  color: var(--text-secondary);
  margin-top: 24px;
  border-top: 1px solid var(--border-color);
  padding-top: 16px;
}
</style>
