<template>
  <div class="glass-card blocker-kanban-card">
    <div class="card-header">
      <div class="card-title">
        <span class="accent-bar"></span>
        <span>技术阻碍排障三关看板 (近14天)</span>
      </div>
      <span class="badge badge-primary">{{ blockers.length }} 项卡点待攻坚</span>
    </div>

    <div class="kanban-grid-3">
      <!-- 第一关：待排查 -->
      <div class="kanban-col">
        <div class="kanban-col-head">
          <div class="head-left">
            <span class="col-dot dot-danger"></span>
            <span>待排查</span>
          </div>
          <span class="badge badge-danger">{{ todoBlockers.length }}</span>
        </div>
        <div class="kanban-items">
          <div v-if="todoBlockers.length === 0" class="kanban-empty">无待排查阻碍</div>
          <div v-for="b in todoBlockers" :key="b.log_id" class="kanban-item">
            <div class="item-head">
              <span class="badge badge-danger" style="font-size: 10px; padding: 1px 6px;">P0 严重</span>
              <span class="item-date">{{ b.date }}</span>
            </div>
            <div class="item-body">{{ b.blocker_text }}</div>
            <div class="item-foot">
              <span class="item-project">{{ b.project_name }}</span>
              <strong class="item-author">{{ b.author_name }}</strong>
            </div>
          </div>
        </div>
      </div>

      <!-- 第二关：攻坚中 -->
      <div class="kanban-col">
        <div class="kanban-col-head">
          <div class="head-left">
            <span class="col-dot dot-warning"></span>
            <span>攻坚中</span>
          </div>
          <span class="badge badge-warning">{{ doingBlockers.length }}</span>
        </div>
        <div class="kanban-items">
          <div v-if="doingBlockers.length === 0" class="kanban-empty">无攻坚中任务</div>
          <div v-for="b in doingBlockers" :key="b.log_id" class="kanban-item">
            <div class="item-head">
              <span class="badge badge-warning" style="font-size: 10px; padding: 1px 6px;">P1 攻坚</span>
              <span class="item-date">{{ b.date }}</span>
            </div>
            <div class="item-body">{{ b.blocker_text }}</div>
            <div class="item-foot">
              <span class="item-project">{{ b.project_name }}</span>
              <strong class="item-author">{{ b.author_name }}</strong>
            </div>
          </div>
        </div>
      </div>

      <!-- 第三关：已闭环 -->
      <div class="kanban-col">
        <div class="kanban-col-head">
          <div class="head-left">
            <span class="col-dot dot-success"></span>
            <span>已闭环</span>
          </div>
          <span class="badge badge-success">{{ doneBlockers.length }}</span>
        </div>
        <div class="kanban-items">
          <div v-if="doneBlockers.length === 0" class="kanban-empty">暂无闭环项</div>
          <div v-for="b in doneBlockers" :key="b.log_id" class="kanban-item">
            <div class="item-head">
              <span class="badge badge-success" style="font-size: 10px; padding: 1px 6px;">已修复</span>
              <span class="item-date">{{ b.date }}</span>
            </div>
            <div class="item-body">{{ b.blocker_text }}</div>
            <div class="item-foot">
              <span class="item-project">{{ b.project_name }}</span>
              <strong class="item-author">{{ b.author_name }}</strong>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  blockers: {
    type: Array,
    default: () => []
  }
})

// 将卡点三等分到三关看板 (待排查 / 攻坚中 / 已闭环)
const todoBlockers = computed(() => {
  return props.blockers.slice(0, Math.ceil(props.blockers.length / 3))
})

const doingBlockers = computed(() => {
  const start = Math.ceil(props.blockers.length / 3)
  const end = Math.ceil((props.blockers.length * 2) / 3)
  return props.blockers.slice(start, end)
})

const doneBlockers = computed(() => {
  const start = Math.ceil((props.blockers.length * 2) / 3)
  return props.blockers.slice(start)
})
</script>

<style scoped>
.blocker-kanban-card {
  height: 100%;
}

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

.kanban-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.kanban-col {
  background: var(--bg-subtle);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.kanban-col-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--border-color);
}

.head-left {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main);
}

.col-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.dot-danger { background: var(--danger); }
.dot-warning { background: var(--warning); }
.dot-success { background: var(--success); }

.kanban-items {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 280px;
  overflow-y: auto;
}

.kanban-item {
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  padding: 10px 12px;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
  transition: all 0.15s ease;
}

.kanban-item:hover {
  box-shadow: 0 3px 8px rgba(0, 0, 0, 0.06);
  border-color: #CFD5DE;
}

.item-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.item-date {
  color: var(--text-secondary);
  font-size: 11px;
}

.item-body {
  font-size: 12px;
  color: var(--text-main);
  line-height: 1.5;
}

.item-foot {
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: var(--text-muted);
  font-size: 11px;
  border-top: 1px solid var(--border-light);
  padding-top: 6px;
  margin-top: 2px;
}

.item-project {
  color: var(--primary);
  font-weight: 500;
}

.item-author {
  color: var(--text-main);
  font-weight: 500;
}

.kanban-empty {
  text-align: center;
  padding: 24px 0;
  font-size: 12px;
  color: var(--text-secondary);
}
</style>
