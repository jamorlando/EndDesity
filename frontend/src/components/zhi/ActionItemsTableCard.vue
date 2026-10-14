<template>
  <div class="glass-card action-items-table-card">
    <div class="card-header">
      <div class="card-title">
        <span class="accent-bar"></span>
        <span>复盘决议改进行动项清单 (TAPD 军令状)</span>
      </div>
      <button @click="$emit('refresh')" class="btn btn-secondary btn-sm">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="23 4 23 10 17 10"/>
          <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
        </svg>
        刷新任务
      </button>
    </div>

    <div class="items-list">
      <div v-if="items.length === 0" class="empty-hint">暂无待跟进的复盘行动项</div>
      <div 
        v-for="act in items" 
        :key="act.id" 
        class="act-card"
        :class="`border-${act.status.toLowerCase()}`"
      >
        <div class="act-header">
          <div class="act-title-box">
            <span class="badge badge-primary" style="font-size: 11px;">{{ act.priority || 'P1' }}</span>
            <span class="act-title">{{ act.title }}</span>
          </div>
          <span :class="statusBadgeClass(act.status)">{{ statusText(act.status) }}</span>
        </div>
        <p class="act-desc">{{ act.description }}</p>
        
        <div class="act-meta">
          <span>责任人：<strong class="text-main">{{ act.assignee_name }}</strong></span>
          <span>截止期限：<strong class="text-main">{{ act.deadline }}</strong></span>
        </div>

        <div v-if="act.result_summary" class="act-result">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
            <polyline points="22 4 12 14.01 9 11.01"/>
          </svg>
          <span><strong>验收凭据：</strong>{{ act.result_summary }}</span>
        </div>

        <div class="act-actions">
          <button 
            v-if="act.status === 'TODO'" 
            @click="$emit('update-status', act.id, 'DOING')" 
            class="btn btn-primary btn-sm"
          >
            启动攻坚推进
          </button>
          <button 
            v-if="act.status === 'DOING' || act.status === 'OVERDUE'" 
            @click="$emit('open-complete', act)" 
            class="btn btn-success btn-sm"
          >
            提交成果并闭环
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  items: {
    type: Array,
    default: () => []
  }
})

defineEmits(['refresh', 'update-status', 'open-complete'])

const statusText = (status) => {
  const map = {
    TODO: '待办立项',
    DOING: '攻坚中',
    DONE: '已成功闭环',
    OVERDUE: '已逾期'
  }
  return map[status] || status
}

const statusBadgeClass = (status) => {
  if (status === 'DONE') return 'badge badge-success'
  if (status === 'DOING') return 'badge badge-warning'
  if (status === 'OVERDUE') return 'badge badge-danger'
  return 'badge badge-neutral'
}
</script>

<style scoped>
.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
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

.items-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-height: 520px;
  overflow-y: auto;
}

.act-card {
  background: #FFFFFF;
  border-radius: 8px;
  padding: 14px 16px;
  border: 1px solid var(--border-color);
  display: flex;
  flex-direction: column;
  gap: 8px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
  transition: all 0.15s ease;
}

.act-card:hover {
  border-color: #CFD5DE;
  box-shadow: 0 3px 8px rgba(0, 0, 0, 0.05);
}

.border-todo { border-left: 3px solid var(--text-secondary); }
.border-doing { border-left: 3px solid var(--warning); }
.border-done { border-left: 3px solid var(--success); }
.border-overdue { border-left: 3px solid var(--danger); }

.act-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.act-title-box {
  display: flex;
  align-items: center;
  gap: 8px;
}

.act-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main);
}

.act-desc {
  font-size: 12px;
  color: var(--text-muted);
  line-height: 1.5;
}

.act-meta {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: var(--text-muted);
  border-top: 1px solid var(--border-light);
  padding-top: 8px;
}

.text-main {
  color: var(--text-main);
}

.act-result {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  background: var(--success-bg);
  border: 1px solid var(--success-border);
  border-radius: 6px;
  font-size: 12px;
  color: var(--success);
}

.act-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 4px;
}

.empty-hint {
  text-align: center;
  padding: 36px 0;
  color: var(--text-secondary);
  font-size: 13px;
}
</style>
