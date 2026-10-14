<template>
  <div class="yan-view">
    <!-- 头部栏 (现代企业级 AI 网关与模型调度) -->
    <div class="view-hero-bar">
      <div>
        <div class="hero-tag-row">
          <span class="badge badge-primary">智能引擎底座</span>
          <span class="text-secondary" style="font-size: 12px;">OpenAI / MCP / DeepSeek 协议兼容</span>
        </div>
        <h1 class="hero-title">AI 智能复盘归因中枢与多模型网关</h1>
        <p class="hero-desc">高可用云端大模型路由 · 企业级深度推演引擎 · SSE 实时流式交互与全链路审计</p>
      </div>
      <div class="hero-actions">
        <span class="badge badge-success" style="padding: 6px 12px; font-size: 12px;">
          ● 智能网关双通道就绪 (高可用热备保障)
        </span>
      </div>
    </div>

    <!-- AI 模型与数据源控制台 -->
    <div style="margin-bottom: 20px;">
      <AiEngineConfigCard 
        :models="models"
        @refresh="fetchModels"
      />
    </div>

    <!-- AI 实时流式控制台 -->
    <div style="margin-bottom: 20px;">
      <AiMemorialScroll 
        @stream-complete="fetchLogs"
      />
    </div>

    <!-- LLM Token 消耗与耗时全链路审计 (仅主管与管理员可见) -->
    <div v-if="authStore.isLeader" class="glass-card">
      <div class="card-header">
        <div class="card-title">
          <span class="accent-bar"></span>
          <span>大模型调用全链路 Token 消耗与延迟审计</span>
        </div>
        <button @click="fetchLogs" class="btn btn-secondary btn-sm">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="23 4 23 10 17 10"/>
            <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
          </svg>
          刷新审计流
        </button>
      </div>

      <div class="table-container">
        <table class="ink-table">
          <thead>
            <tr>
              <th>调用ID</th>
              <th>模型标识</th>
              <th>输入 Tokens</th>
              <th>输出 Tokens</th>
              <th>总消耗</th>
              <th>响应延迟</th>
              <th>调用状态</th>
              <th>调用时间</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="callLogs.length === 0">
              <td colspan="8" class="text-center" style="padding: 36px; color: var(--text-secondary); text-align: center;">暂无审计调用记录</td>
            </tr>
            <tr v-for="log in callLogs" :key="log.id">
              <td>#{{ log.id }}</td>
              <td><strong>{{ getModelName(log.ai_model_id) }}</strong></td>
              <td>{{ log.prompt_tokens }}</td>
              <td>{{ log.completion_tokens }}</td>
              <td><strong style="color: var(--primary);">{{ log.total_tokens }}</strong></td>
              <td>{{ log.latency_ms }} ms</td>
              <td>
                <span :class="log.call_status === 'SUCCESS' ? 'badge badge-success' : 'badge badge-danger'">
                  {{ log.call_status }}
                </span>
              </td>
              <td>{{ log.created_at }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '../../stores/auth'
import AiEngineConfigCard from '../../components/yan/AiEngineConfigCard.vue'
import AiMemorialScroll from '../../components/yan/AiMemorialScroll.vue'
import { getAiModelsApi, getLlmCallLogsApi } from '../../api/ai'

const authStore = useAuthStore()

const models = ref([])
const callLogs = ref([])

const fetchModels = async () => {
  try {
    const res = await getAiModelsApi()
    models.value = res || []
  } catch (e) {
    console.error(e)
  }
}

const fetchLogs = async () => {
  if (!authStore.isLeader) return
  try {
    const res = await getLlmCallLogsApi(15)
    callLogs.value = res || []
  } catch (e) {
    console.error(e)
  }
}

const getModelName = (modelId) => {
  const m = models.value.find(item => item.id === modelId)
  return m ? m.model_identifier : `Model #${modelId}`
}

onMounted(() => {
  fetchModels()
  if (authStore.isLeader) {
    fetchLogs()
  }
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

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
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

.table-container {
  overflow-x: auto;
}
</style>
