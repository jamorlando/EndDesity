<template>
  <div class="glass-card heatmap-card">
    <div class="card-header">
      <div class="card-title">
        <span class="accent-bar"></span>
        <span>个人月度出勤与填报热力图 ({{ currentYear }}年{{ currentMonth }}月)</span>
      </div>
      <div class="month-nav">
        <button @click="prevMonth" class="btn btn-secondary btn-sm">‹ 上月</button>
        <button @click="nextMonth" class="btn btn-secondary btn-sm">下月 ›</button>
      </div>
    </div>

    <div class="calendar-grid">
      <div v-for="d in weekDays" :key="d" class="cal-header-cell">{{ d }}</div>
      <div 
        v-for="(day, idx) in heatmapDays" 
        :key="idx"
        class="cal-day-cell"
        :class="[
          `status-${day.status.toLowerCase()}`,
          { 'is-today': day.date === todayStr }
        ]"
        @click="$emit('day-click', day)"
      >
        <div class="day-num">{{ day.date.slice(8) }}</div>
        <div v-if="day.spent_hours > 0" class="day-hours">{{ day.spent_hours }}h</div>
        <div class="day-status-dot"></div>
      </div>
    </div>

    <div class="cal-legend">
      <span class="legend-item"><span class="dot dot-submitted"></span> 准时提交</span>
      <span class="legend-item"><span class="dot dot-delayed"></span> 补交/迟交</span>
      <span class="legend-item"><span class="dot dot-absent"></span> 待填报/缺勤</span>
      <span class="legend-item"><span class="dot dot-rest"></span> 节假日休假</span>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getCalendarHeatmapApi } from '../../api/workLogs'

const emit = defineEmits(['day-click'])

const weekDays = ['一', '二', '三', '四', '五', '六', '日']
const todayStr = new Date().toISOString().slice(0, 10)

const currentYear = ref(2026)
const currentMonth = ref(9)
const heatmapDays = ref([])

const fetchHeatmap = async () => {
  try {
    const res = await getCalendarHeatmapApi({ year: currentYear.value, month: currentMonth.value })
    heatmapDays.value = res || []
  } catch (e) {
    console.error(e)
  }
}

const prevMonth = () => {
  if (currentMonth.value === 1) {
    currentYear.value -= 1
    currentMonth.value = 12
  } else {
    currentMonth.value -= 1
  }
  fetchHeatmap()
}

const nextMonth = () => {
  if (currentMonth.value === 12) {
    currentYear.value += 1
    currentMonth.value = 1
  } else {
    currentMonth.value += 1
  }
  fetchHeatmap()
}

defineExpose({ fetchHeatmap })

onMounted(() => {
  fetchHeatmap()
})
</script>

<style scoped>
.heatmap-card {
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
  background: var(--success);
  border-radius: 2px;
  display: inline-block;
}

.month-nav {
  display: flex;
  gap: 6px;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 6px;
}

.cal-header-cell {
  text-align: center;
  font-size: 12px;
  color: var(--text-muted);
  padding: 4px 0;
  font-weight: 600;
}

.cal-day-cell {
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  min-height: 48px;
  padding: 6px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  cursor: pointer;
  transition: all 0.15s ease;
}

.cal-day-cell:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.05);
  border-color: var(--primary);
}

.day-num {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-main);
}

.day-hours {
  font-size: 11px;
  color: var(--primary);
  font-weight: 600;
}

.day-status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  align-self: flex-end;
}

.status-submitted .day-status-dot { background: var(--success); }
.status-delayed .day-status-dot { background: var(--warning); }
.status-absent .day-status-dot { background: var(--danger); }
.status-rest .day-status-dot { background: #C9CDD4; }
.status-future .day-status-dot { background: transparent; }

.is-today {
  border: 2px solid var(--primary);
  background: var(--primary-light);
}

.cal-legend {
  display: flex;
  gap: 16px;
  margin-top: 14px;
  font-size: 12px;
  color: var(--text-muted);
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.dot-submitted { background: var(--success); }
.dot-delayed { background: var(--warning); }
.dot-absent { background: var(--danger); }
.dot-rest { background: #C9CDD4; }
</style>
