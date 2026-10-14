<template>
  <div class="mo-view">
    <!-- 头部栏 (现代工业级效能全景大屏) -->
    <div class="view-hero-bar">
      <div>
        <div class="hero-tag-row">
          <span class="badge badge-primary">度量决策中枢</span>
          <span class="text-secondary" style="font-size: 12px;">DORA / 敏捷交付指标基线</span>
        </div>
        <h1 class="hero-title">研发效能度量与全景大屏</h1>
        <p class="hero-desc">工时饱和度追踪 · 燃尽速率走势 · 五维工程能力雷达画像</p>
      </div>
      <div class="hero-actions">
        <button @click="refreshAll" class="btn btn-secondary">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="23 4 23 10 17 10"></polyline>
            <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path>
          </svg>
          刷新度量指标
        </button>
      </div>
    </div>

    <!-- MetricsKpiCards 四大动能指标卡 -->
    <div style="margin-bottom: 20px;">
      <MetricsKpiCards :overview="overview" />
    </div>

    <!-- 图表两栏布局：燃尽图 + 雷达图 -->
    <div class="charts-grid">
      <!-- 交付速率燃尽折线图 -->
      <VelocityBurnDownChart ref="burndownRef" />

      <!-- 五维能力雷达画像图 -->
      <CompetencyRadarChart ref="radarRef" />
    </div>

    <!-- 每日效能历史聚合快照表 -->
    <div class="glass-card" style="margin-top: 20px;">
      <div class="card-header">
        <div class="card-title">
          <span class="accent-bar"></span>
          <span>每日效能聚合快照历史 (秒开大屏底座)</span>
        </div>
      </div>

      <div class="table-container">
        <table class="ink-table">
          <thead>
            <tr>
              <th>统计日期</th>
              <th>应交人数</th>
              <th>实交人数</th>
              <th>准时提交</th>
              <th>迟交人数</th>
              <th>合规率</th>
              <th>当日总工时</th>
              <th>卡点数</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="snapshots.length === 0">
              <td colspan="8" class="text-center" style="padding: 36px; color: var(--text-secondary); text-align: center;">暂无快照数据</td>
            </tr>
            <tr v-for="s in snapshots" :key="s.id">
              <td><strong>{{ s.snapshot_date }}</strong></td>
              <td>{{ s.expected_count }} 人</td>
              <td>{{ s.actual_count }} 人</td>
              <td>{{ s.on_time_count }} 人</td>
              <td>{{ s.delayed_count }} 人</td>
              <td>
                <span :class="s.submission_rate >= 90 ? 'badge badge-success' : 'badge badge-warning'">
                  {{ s.submission_rate }}%
                </span>
              </td>
              <td>
                <span style="font-family: var(--font-mono); font-weight: 600; color: var(--primary);">{{ s.total_spent_hours }} h</span>
              </td>
              <td>
                <span :class="s.blocker_count > 0 ? 'badge badge-danger' : 'badge badge-neutral'">{{ s.blocker_count }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import MetricsKpiCards from '../../components/mo/MetricsKpiCards.vue'
import VelocityBurnDownChart from '../../components/mo/VelocityBurnDownChart.vue'
import CompetencyRadarChart from '../../components/mo/CompetencyRadarChart.vue'
import { getStatsOverviewApi, getSnapshotsApi } from '../../api/stats'

const burndownRef = ref(null)
const radarRef = ref(null)

const overview = reactive({
  team_name: '研发中枢',
  member_count: 8,
  submission_rate: 96.5,
  on_time_rate: 94.2,
  total_spent_hours: 480.0,
  active_blockers_count: 5,
  open_action_items_count: 3
})

const snapshots = ref([])

const fetchOverview = async () => {
  try {
    const res = await getStatsOverviewApi()
    if (res) Object.assign(overview, res)
  } catch (e) {
    console.error(e)
  }
}

const fetchSnapshots = async () => {
  try {
    const res = await getSnapshotsApi({ limit: 15 })
    snapshots.value = res || []
  } catch (e) {
    console.error(e)
  }
}

const refreshAll = () => {
  fetchOverview()
  burndownRef.value?.renderChart()
  radarRef.value?.renderRadar()
  fetchSnapshots()
}

onMounted(() => {
  fetchOverview()
  fetchSnapshots()
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

.charts-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

@media (min-width: 1024px) {
  .charts-grid {
    grid-template-columns: 1.2fr 0.8fr;
  }
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
