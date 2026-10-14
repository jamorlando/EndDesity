<template>
  <div class="glass-card team-worklog-list-card">
    <!-- 卡片头部与顶栏快捷预设 -->
    <div class="card-header">
      <div class="card-title-group">
        <div class="card-title">
          <span class="accent-bar"></span>
          <span>团队全员近期工作日志流水</span>
        </div>
        <!-- 快捷时间跨度药丸 -->
        <div class="quick-period-pills">
          <button 
            type="button"
            class="period-pill"
            :class="{ active: filters.period === 'ALL' }"
            @click="setPeriod('ALL')"
          >
            全部日志
          </button>
          <button 
            type="button"
            class="period-pill"
            :class="{ active: filters.period === '7D' }"
            @click="setPeriod('7D')"
          >
            近7天
          </button>
          <button 
            type="button"
            class="period-pill"
            :class="{ active: filters.period === '14D' }"
            @click="setPeriod('14D')"
          >
            近14天
          </button>
          <button 
            type="button"
            class="period-pill"
            :class="{ active: filters.period === '30D' }"
            @click="setPeriod('30D')"
          >
            近30天
          </button>
        </div>
      </div>

      <button @click="$emit('refresh')" class="btn btn-secondary btn-sm">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="23 4 23 10 17 10"/>
          <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
        </svg>
        刷新流水
      </button>
    </div>

    <!-- 飞书/TAPD 现代多维组合筛选栏 -->
    <div class="filter-toolbar">
      <!-- 1. 关键词即时搜索 -->
      <div class="search-input-box">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="search-icon">
          <circle cx="11" cy="11" r="8"/>
          <line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <input 
          v-model="filters.keyword" 
          type="text" 
          class="filter-search-input" 
          placeholder="搜索填报人、攻坚工作内容、卡点关键字..." 
        />
        <button v-if="filters.keyword" @click="filters.keyword = ''" class="clear-btn" title="清空搜索">×</button>
      </div>

      <!-- 2. 所属项目下拉筛选 -->
      <div class="filter-select-item">
        <select v-model="filters.projectId" class="form-select filter-select">
          <option :value="null">全部工程项目 (不限)</option>
          <option v-for="p in projects" :key="p.id" :value="p.id">
            {{ p.name }}
          </option>
        </select>
      </div>

      <!-- 3. 合规准时状态筛选 -->
      <div class="filter-select-item">
        <select v-model="filters.delayed" class="form-select filter-select">
          <option :value="null">合规状态 (全部)</option>
          <option :value="0">准时填报</option>
          <option :value="1">迟交 / 补交</option>
        </select>
      </div>

      <!-- 4. 主管评星打分筛选 -->
      <div class="filter-select-item">
        <select v-model="filters.score" class="form-select filter-select">
          <option :value="null">主管评定 (全部)</option>
          <option :value="5">★ 5星 卓越</option>
          <option :value="4">★ 4星 良好</option>
          <option :value="3">★ 3星及以下</option>
          <option :value="0">待主管评分</option>
        </select>
      </div>

      <!-- 5. 重置筛选条件按钮 -->
      <button 
        v-if="hasActiveFilters" 
        @click="resetFilters" 
        class="btn btn-secondary btn-sm reset-filter-btn"
        title="重置所有筛选"
      >
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="18" y1="6" x2="6" y2="18"></line>
          <line x1="6" y1="6" x2="18" y2="18"></line>
        </svg>
        重置筛选
      </button>

      <!-- 统计指标指示 -->
      <div class="filter-count-badge">
        <span>当前展示 <strong>{{ filteredLogs.length }}</strong> / 共 {{ logs.length }} 条日志</span>
      </div>
    </div>

    <!-- 流水数据表格 -->
    <div class="table-container">
      <table class="ink-table">
        <thead>
          <tr>
            <th>归属日期</th>
            <th>填报人</th>
            <th>关联项目</th>
            <th>主要工作内容</th>
            <th>工时</th>
            <th>合规/版本</th>
            <th>主管评定</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <!-- 无匹配数据提示 -->
          <tr v-if="filteredLogs.length === 0">
            <td colspan="8" class="empty-filter-cell">
              <div class="empty-filter-box">
                <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                  <circle cx="11" cy="11" r="8"/>
                  <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                  <line x1="8" y1="11" x2="14" y2="11"/>
                </svg>
                <div class="empty-text">未找到符合当前筛选条件的研发日志</div>
                <button v-if="hasActiveFilters" @click="resetFilters" class="btn btn-primary btn-sm" style="margin-top: 8px;">
                  重置筛选条件
                </button>
              </div>
            </td>
          </tr>

          <!-- 渲染匹配数据行 -->
          <tr v-for="log in filteredLogs" :key="log.id">
            <td><strong>{{ log.log_date }}</strong></td>
            <td>
              <span class="author-cell">{{ log.author_name }}</span>
            </td>
            <td>
              <span class="badge badge-primary" style="font-size: 11px;">
                {{ log.project_name || '通用研发' }}
              </span>
            </td>
            <td style="max-width: 320px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
              {{ log.content_json?.task || log.content_json?.summary || '日常开发' }}
            </td>
            <td>
              <span class="hours-text">{{ log.spent_hours }} h</span>
            </td>
            <td>
              <span :class="log.is_delayed ? 'badge badge-warning' : 'badge badge-success'">
                {{ log.is_delayed ? '补交' : '准时' }}
              </span>
              <span class="version-badge">v{{ log.current_version }}</span>
            </td>
            <td>
              <span v-if="log.score" class="score-stars">★ {{ log.score }} 星</span>
              <span v-else style="color: var(--text-secondary); font-size: 12px;">待打分</span>
            </td>
            <td>
              <div class="action-btns">
                <button @click="$emit('view-detail', log.id)" class="btn-link">详情/时光机</button>
                <button v-if="isLeader" @click="$emit('score', log)" class="btn-link">评分批注</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { reactive, computed } from 'vue'

const props = defineProps({
  logs: {
    type: Array,
    default: () => []
  },
  projects: {
    type: Array,
    default: () => []
  },
  isLeader: {
    type: Boolean,
    default: false
  }
})

defineEmits(['refresh', 'view-detail', 'score'])

// 筛选表单状态
const filters = reactive({
  keyword: '',
  projectId: null,
  delayed: null,
  score: null,
  period: 'ALL'
})

// 快捷时间跨度切换
const setPeriod = (period) => {
  filters.period = period
}

// 是否激活了任意筛选
const hasActiveFilters = computed(() => {
  return !!filters.keyword.trim() || 
         filters.projectId !== null || 
         filters.delayed !== null || 
         filters.score !== null || 
         filters.period !== 'ALL'
})

// 重置全部筛选条件
const resetFilters = () => {
  filters.keyword = ''
  filters.projectId = null
  filters.delayed = null
  filters.score = null
  filters.period = 'ALL'
}

// 毫秒转天数辅助
const parseLogDate = (dateStr) => {
  if (!dateStr) return new Date(0)
  return new Date(dateStr)
}

// 现代前端响应式即时过滤计算属性 (毫秒级响应，无需二次请求网络)
const filteredLogs = computed(() => {
  const now = new Date()
  const kw = filters.keyword.trim().toLowerCase()

  return props.logs.filter(log => {
    // 1. 关键词模糊匹配 (填报人、主要工作内容、卡点阻碍)
    if (kw) {
      const authorMatch = (log.author_name || '').toLowerCase().includes(kw)
      const projectMatch = (log.project_name || '').toLowerCase().includes(kw)
      const taskText = (log.content_json?.task || log.content_json?.summary || '').toLowerCase()
      const taskMatch = taskText.includes(kw)
      const blockerText = (log.content_json?.blockers || log.content_json?.issues || '').toLowerCase()
      const blockerMatch = blockerText.includes(kw)

      if (!authorMatch && !projectMatch && !taskMatch && !blockerMatch) {
        return false
      }
    }

    // 2. 项目筛选
    if (filters.projectId !== null) {
      if (log.project_id !== filters.projectId) {
        return false
      }
    }

    // 3. 合规状态筛选 (0准时 / 1补交)
    if (filters.delayed !== null) {
      if (log.is_delayed !== filters.delayed) {
        return false
      }
    }

    // 4. 主管评星打分筛选 (5星 / 4星 / 3星及以下 / 0未评分)
    if (filters.score !== null) {
      if (filters.score === 0) {
        if (log.score && log.score > 0) return false
      } else if (filters.score === 3) {
        if (!log.score || log.score > 3) return false
      } else {
        if (log.score !== filters.score) return false
      }
    }

    // 5. 快捷周期筛选
    if (filters.period !== 'ALL') {
      const logD = parseLogDate(log.log_date)
      const diffDays = (now - logD) / (1000 * 60 * 60 * 24)
      if (filters.period === '7D' && diffDays > 7) return false
      if (filters.period === '14D' && diffDays > 14) return false
      if (filters.period === '30D' && diffDays > 30) return false
    }

    return true
  })
})
</script>

<style scoped>
.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
  flex-wrap: wrap;
  gap: 12px;
}

.card-title-group {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
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

/* 快捷周期药丸组 */
.quick-period-pills {
  display: flex;
  align-items: center;
  gap: 4px;
  background: var(--bg-subtle);
  padding: 3px;
  border-radius: 6px;
  border: 1px solid var(--border-color);
}

.period-pill {
  background: transparent;
  border: none;
  font-size: 12px;
  color: var(--text-muted);
  padding: 3px 10px;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s ease;
  font-weight: 500;
}

.period-pill:hover {
  color: var(--text-main);
}

.period-pill.active {
  background: #FFFFFF;
  color: var(--primary);
  font-weight: 600;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

/* 多维组合筛选工具栏 (飞书 / TAPD 标准) */
.filter-toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  padding: 12px 14px;
  background: var(--bg-subtle);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  margin-bottom: 16px;
}

.search-input-box {
  position: relative;
  display: flex;
  align-items: center;
  min-width: 260px;
  flex: 1;
}

.search-icon {
  position: absolute;
  left: 10px;
  color: var(--text-secondary);
  pointer-events: none;
}

.filter-search-input {
  width: 100%;
  padding: 6px 28px 6px 30px;
  font-size: 13px;
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  outline: none;
  color: var(--text-main);
  transition: all 0.15s ease;
}

.filter-search-input:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px rgba(51, 112, 255, 0.12);
}

.clear-btn {
  position: absolute;
  right: 8px;
  background: transparent;
  border: none;
  color: var(--text-secondary);
  font-size: 16px;
  cursor: pointer;
  line-height: 1;
}

.filter-select-item {
  min-width: 140px;
}

.filter-select {
  padding: 6px 10px;
  font-size: 12px;
  border-radius: 6px;
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  color: var(--text-main);
  outline: none;
  cursor: pointer;
}

.reset-filter-btn {
  gap: 4px;
  padding: 5px 10px;
  font-size: 12px;
}

.filter-count-badge {
  margin-left: auto;
  font-size: 12px;
  color: var(--text-secondary);
}

.filter-count-badge strong {
  color: var(--primary);
}

/* 表格与数据单元格 */
.table-container {
  overflow-x: auto;
}

.author-cell {
  font-weight: 500;
  color: var(--text-main);
}

.hours-text {
  font-family: var(--font-mono);
  font-weight: 600;
  color: var(--primary);
}

.version-badge {
  display: inline-block;
  font-size: 10px;
  padding: 1px 5px;
  background: #F2F3F5;
  color: var(--text-muted);
  border-radius: 3px;
  margin-left: 4px;
}

.score-stars {
  color: #FF7D00;
  font-weight: 600;
  font-size: 12px;
}

.action-btns {
  display: flex;
  gap: 12px;
}

.btn-link {
  background: none;
  border: none;
  color: var(--primary);
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  padding: 0;
  transition: color 0.15s;
}

.btn-link:hover {
  color: var(--primary-hover);
  text-decoration: underline;
}

/* 空状态单元格 */
.empty-filter-cell {
  padding: 48px 0;
  text-align: center;
}

.empty-filter-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  color: var(--text-secondary);
}

.empty-text {
  font-size: 13px;
  color: var(--text-muted);
}
</style>
