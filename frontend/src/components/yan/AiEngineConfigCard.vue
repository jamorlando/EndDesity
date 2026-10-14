<template>
  <div class="glass-card ai-config-card">
    <div class="card-header">
      <div class="card-title">
        <span class="accent-bar"></span>
        <span>已接入的 AI 模型与智能网关路由策略</span>
      </div>
      <button @click="$emit('refresh')" class="btn btn-secondary btn-sm">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="23 4 23 10 17 10"/>
          <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
        </svg>
        刷新状态
      </button>
    </div>

    <div class="models-grid">
      <div v-for="m in models" :key="m.id" class="model-item-card">
        <div class="model-head">
          <span class="model-name">{{ m.model_identifier }}</span>
          <span v-if="m.is_default" class="badge badge-primary">主力默认</span>
          <span v-else class="badge badge-success">备用热备</span>
        </div>
        <div class="model-provider">模型服务商：<strong class="text-main">{{ m.provider_name }}</strong></div>
        <div class="model-metrics">
          <span>上下文窗口: <strong>{{ m.context_window }}</strong> tokens</span>
          <span>单次上限: <strong>{{ m.max_tokens }}</strong> tokens</span>
          <span>温度参数: <strong>{{ m.temperature }}</strong></span>
        </div>
        <div class="model-url">{{ m.api_base_url }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  models: {
    type: Array,
    default: () => []
  }
})

defineEmits(['refresh'])
</script>

<style scoped>
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

.models-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 14px;
}

@media (min-width: 768px) {
  .models-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.model-item-card {
  background: var(--bg-subtle);
  border-radius: 8px;
  padding: 16px;
  border: 1px solid var(--border-color);
  transition: all 0.15s ease;
}

.model-item-card:hover {
  border-color: #CFD5DE;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.model-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.model-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-main);
  font-family: var(--font-mono);
}

.model-provider {
  font-size: 12px;
  color: var(--text-muted);
  margin-bottom: 8px;
}

.text-main {
  color: var(--text-main);
}

.model-metrics {
  display: flex;
  gap: 12px;
  font-size: 11px;
  color: var(--text-secondary);
  margin-bottom: 10px;
  flex-wrap: wrap;
}

.model-metrics strong {
  color: var(--text-main);
}

.model-url {
  font-size: 11px;
  font-family: var(--font-mono);
  color: var(--text-muted);
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  padding: 4px 8px;
  border-radius: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
