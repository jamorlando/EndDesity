<template>
  <div class="metrics-kpi-grid">
    <div class="metric-card glass-card">
      <div class="metric-head">
        <span class="metric-label">日志按时合规率</span>
        <span class="badge badge-success">基准 >90%</span>
      </div>
      <div class="metric-val text-success">
        {{ overview.on_time_rate }}<span class="metric-unit">%</span>
      </div>
      <div class="metric-sub">
        总填报率: {{ overview.submission_rate }}% · 团队在编: {{ overview.member_count }} 人
      </div>
    </div>

    <div class="metric-card glass-card">
      <div class="metric-head">
        <span class="metric-label">研发周期总工时</span>
        <span class="badge badge-primary">近30天累计</span>
      </div>
      <div class="metric-val text-primary">
        {{ overview.total_spent_hours }}<span class="metric-unit">h</span>
      </div>
      <div class="metric-sub">人均工时饱和度正常 · 交付稳步推进</div>
    </div>

    <div class="metric-card glass-card">
      <div class="metric-head">
        <span class="metric-label">活跃攻坚卡点数</span>
        <span class="badge badge-danger">阻碍待破</span>
      </div>
      <div class="metric-val text-danger">
        {{ overview.active_blockers_count }}<span class="metric-unit">项</span>
      </div>
      <div class="metric-sub">已同步汇总至攻坚看板与复盘矩阵</div>
    </div>

    <div class="metric-card glass-card">
      <div class="metric-head">
        <span class="metric-label">待闭环改进军令状</span>
        <span class="badge badge-warning">责任到人</span>
      </div>
      <div class="metric-val text-warning">
        {{ overview.open_action_items_count }}<span class="metric-unit">条</span>
      </div>
      <div class="metric-sub">复盘改进措施持续推进监督中</div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  overview: {
    type: Object,
    default: () => ({
      on_time_rate: 95.0,
      submission_rate: 96.5,
      total_spent_hours: 480.0,
      active_blockers_count: 5,
      open_action_items_count: 3,
      member_count: 8
    })
  }
})
</script>

<style scoped>
.metrics-kpi-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

@media (min-width: 1024px) {
  .metrics-kpi-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

.metric-card {
  padding: 18px 20px;
}

.metric-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.metric-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--text-muted);
}

.metric-val {
  font-size: 32px;
  font-weight: 700;
  font-family: var(--font-sans);
  line-height: 1.1;
  margin-bottom: 6px;
}

.metric-unit {
  font-size: 14px;
  font-weight: normal;
  color: var(--text-muted);
  margin-left: 2px;
}

.metric-sub {
  font-size: 12px;
  color: var(--text-secondary);
}
</style>
