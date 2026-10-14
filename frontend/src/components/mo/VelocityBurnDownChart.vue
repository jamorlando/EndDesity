<template>
  <div class="glass-card chart-card">
    <div class="card-header">
      <div class="card-title">
        <span class="accent-bar"></span>
        <span>迭代工时燃尽与实际投入走势 (近14天)</span>
      </div>
      <span class="chart-subtitle">理想燃烧线 vs 实际投入工时</span>
    </div>
    <div ref="chartRef" class="chart-box"></div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { getBurnDownApi } from '../../api/stats'

const chartRef = ref(null)
let myChart = null

const renderChart = async () => {
  if (!chartRef.value) return
  if (!myChart) {
    myChart = echarts.init(chartRef.value)
  }

  try {
    const points = await getBurnDownApi({ days: 14 }) || []
    const dates = points.map(p => p.date)
    const spent = points.map(p => p.spent_hours)
    const remaining = points.map(p => p.remaining_hours)

    const option = {
      tooltip: { 
        trigger: 'axis',
        backgroundColor: '#FFFFFF',
        borderColor: '#DEE0E3',
        textStyle: { color: '#1F2329' }
      },
      legend: {
        data: ['当日投入工时', '剩余总工时'],
        bottom: 0,
        textStyle: { color: '#646A73', fontSize: 12 }
      },
      grid: { left: '3%', right: '4%', bottom: '12%', top: '8%', containLabel: true },
      xAxis: {
        type: 'category',
        data: dates,
        axisLine: { lineStyle: { color: '#DEE0E3' } },
        axisLabel: { color: '#646A73', fontSize: 11 }
      },
      yAxis: {
        type: 'value',
        axisLine: { lineStyle: { color: '#DEE0E3' } },
        splitLine: { lineStyle: { color: '#EFF0F1' } },
        axisLabel: { color: '#646A73', fontSize: 11 }
      },
      series: [
        {
          name: '当日投入工时',
          type: 'bar',
          data: spent,
          itemStyle: { color: '#3370FF', borderRadius: [4, 4, 0, 0] },
          barMaxWidth: 20
        },
        {
          name: '剩余总工时',
          type: 'line',
          data: remaining,
          smooth: true,
          itemStyle: { color: '#00B42A' },
          lineStyle: { width: 3 }
        }
      ]
    }
    if (!myChart || myChart.isDisposed()) return
    myChart.setOption(option)
  } catch (e) {
    console.error(e)
  }
}

const resize = () => {
  if (myChart && !myChart.isDisposed()) {
    myChart.resize()
  }
}

defineExpose({ renderChart, resize })

onMounted(() => {
  renderChart()
  window.addEventListener('resize', resize)
})

onUnmounted(() => {
  window.removeEventListener('resize', resize)
  if (myChart) {
    myChart.dispose()
    myChart = null
  }
})
</script>

<style scoped>
.chart-card {
  height: 100%;
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

.chart-subtitle {
  font-size: 12px;
  color: var(--text-muted);
}

.chart-box {
  width: 100%;
  height: 340px;
}
</style>
