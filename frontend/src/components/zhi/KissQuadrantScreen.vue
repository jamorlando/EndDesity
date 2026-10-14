<template>
  <div class="kiss-quadrant-screen-container">
    <div class="screens-grid-4">
      <!-- 象限一：KEEP 持续保持 -->
      <div class="kiss-quadrant-card quad-keep">
        <div class="quad-header">
          <div class="quad-tag-badge badge-keep">
            <span class="dot-indicator"></span>
            <span>KEEP · 持续保持</span>
          </div>
          <h3 class="quad-title">优秀工程实践与团队壁垒</h3>
          <p class="quad-desc">已验证行之有效的规范、沉淀的最佳实践与高效协作</p>
        </div>
        <ul class="quad-list">
          <li v-for="(item, idx) in keepItems" :key="idx" class="quad-list-item">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="item-icon icon-keep">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
            <span>{{ item }}</span>
          </li>
        </ul>
        <div class="quad-footer">
          <span class="quad-counter">{{ keepItems.length }} 项实践</span>
        </div>
      </div>

      <!-- 象限二：IMPROVE 痛点改进 -->
      <div class="kiss-quadrant-card quad-improve">
        <div class="quad-header">
          <div class="quad-tag-badge badge-improve">
            <span class="dot-indicator"></span>
            <span>IMPROVE · 瓶颈改进</span>
          </div>
          <h3 class="quad-title">现存堵点与排障效率</h3>
          <p class="quad-desc">研发流程堵点、联调等待、排障诊断慢与沟通断层</p>
        </div>
        <ul class="quad-list">
          <li v-for="(item, idx) in improveItems" :key="idx" class="quad-list-item">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="item-icon icon-improve">
              <circle cx="12" cy="12" r="10"/>
              <line x1="12" y1="8" x2="12" y2="12"/>
              <line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            <span>{{ item }}</span>
          </li>
        </ul>
        <div class="quad-footer">
          <span class="quad-counter">{{ improveItems.length }} 个堵点</span>
        </div>
      </div>

      <!-- 象限三：START 尝试引入 -->
      <div class="kiss-quadrant-card quad-start">
        <div class="quad-header">
          <div class="quad-tag-badge badge-start">
            <span class="dot-indicator"></span>
            <span>START · 建议启动</span>
          </div>
          <h3 class="quad-title">新举措与智能化工具</h3>
          <p class="quad-desc">引入 SSE 流式诊断、防回归自动化基线与效能看板</p>
        </div>
        <ul class="quad-list">
          <li v-for="(item, idx) in startItems" :key="idx" class="quad-list-item">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="item-icon icon-start">
              <line x1="12" y1="5" x2="12" y2="19"/>
              <line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            <span>{{ item }}</span>
          </li>
        </ul>
        <div class="quad-footer">
          <span class="quad-counter">{{ startItems.length }} 条创新</span>
        </div>
      </div>

      <!-- 象限四：STOP 终止阻碍 -->
      <div class="kiss-quadrant-card quad-stop">
        <div class="quad-header">
          <div class="quad-tag-badge badge-stop">
            <span class="dot-indicator"></span>
            <span>STOP · 立即摒弃</span>
          </div>
          <h3 class="quad-title">低效习惯与风险戒律</h3>
          <p class="quad-desc">停止外部不可信依赖引入、杜绝口头无责任人的复盘</p>
        </div>
        <ul class="quad-list">
          <li v-for="(item, idx) in stopItems" :key="idx" class="quad-list-item">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="item-icon icon-stop">
              <circle cx="12" cy="12" r="10"/>
              <line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
            </svg>
            <span>{{ item }}</span>
          </li>
        </ul>
        <div class="quad-footer">
          <span class="quad-counter">{{ stopItems.length }} 条戒律</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  kissData: {
    type: Object,
    default: () => ({
      keep: [],
      improve: [],
      start: [],
      stop: []
    })
  }
})

const keepItems = computed(() => props.kissData.keep || [])
const improveItems = computed(() => props.kissData.improve || [])
const startItems = computed(() => props.kissData.start || [])
const stopItems = computed(() => props.kissData.stop || [])
</script>

<style scoped>
.screens-grid-4 {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
}

@media (min-width: 640px) {
  .screens-grid-4 {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1200px) {
  .screens-grid-4 {
    grid-template-columns: repeat(4, 1fr);
  }
}

.kiss-quadrant-card {
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 18px 20px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  min-height: 400px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
  transition: all 0.2s ease;
}

.kiss-quadrant-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.06);
}

.quad-keep {
  border-top: 3px solid var(--success);
}

.quad-improve {
  border-top: 3px solid var(--warning);
}

.quad-start {
  border-top: 3px solid var(--primary);
}

.quad-stop {
  border-top: 3px solid var(--danger);
}

.quad-tag-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 4px;
  margin-bottom: 8px;
}

.dot-indicator {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.badge-keep {
  background: var(--success-bg);
  color: var(--success);
}
.badge-keep .dot-indicator { background: var(--success); }

.badge-improve {
  background: var(--warning-bg);
  color: var(--warning);
}
.badge-improve .dot-indicator { background: var(--warning); }

.badge-start {
  background: var(--primary-light);
  color: var(--primary);
}
.badge-start .dot-indicator { background: var(--primary); }

.badge-stop {
  background: var(--danger-bg);
  color: var(--danger);
}
.badge-stop .dot-indicator { background: var(--danger); }

.quad-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-main);
  margin-bottom: 4px;
}

.quad-desc {
  font-size: 12px;
  color: var(--text-muted);
  line-height: 1.4;
  margin-bottom: 14px;
}

.quad-list {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 10px;
  flex: 1;
}

.quad-list-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 12px;
  line-height: 1.5;
  color: var(--text-main);
}

.item-icon {
  margin-top: 2px;
  flex-shrink: 0;
}

.icon-keep { color: var(--success); }
.icon-improve { color: var(--warning); }
.icon-start { color: var(--primary); }
.icon-stop { color: var(--danger); }

.quad-footer {
  border-top: 1px solid var(--border-light);
  padding-top: 10px;
  margin-top: 14px;
  display: flex;
  justify-content: flex-end;
}

.quad-counter {
  font-size: 11px;
  color: var(--text-secondary);
  font-weight: 500;
}
</style>
