<template>
  <div class="glass-card radar-card">
    <div class="card-header">
      <div class="card-title">
        <span class="accent-bar"></span>
        <span>研发效能五维综合画像 (个人 vs 团队均值)</span>
      </div>
      <span class="chart-subtitle">规范 / 交付 / 攻坚 / 协作 / 文档</span>
    </div>
    <div ref="radarRef" class="radar-box"></div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { getRadarApi } from '../../api/stats'

const radarRef = ref(null)
let myChart = null

const renderRadar = async () => {
  if (!radarRef.value) return
  if (!myChart) {
    myChart = echarts.init(radarRef.value)
  }

  try {
    const data = await getRadarApi() || {}
    const indicators = data.indicators || [
      { name: '代码质量与规范', max: 100 },
      { name: '工期交付准时率', max: 100 },
      { name: '难题攻坚突破力', max: 100 },
      { name: '团队复盘协作度', max: 100 },
      { name: '文档与知识沉淀', max: 100 }
    ]

    const option = {
      tooltip: {
        backgroundColor: '#FFFFFF',
        borderColor: '#DEE0E3',
        textStyle: { color: '#1F2329' }
      },
      legend: {
        data: ['个人画像', '团队均值'],
        bottom: 0,
        textStyle: { color: '#646A73', fontSize: 12 }
      },
      radar: {
        indicator: indicators.map(i => ({ name: i.name, max: 100 })),
        splitArea: {
          areaStyle: {
            color: ['#FFFFFF', '#F7F8FA']
          }
        },
        axisLine: { lineStyle: { color: '#DEE0E3' } },
        splitLine: { lineStyle: { color: '#EFF0F1' } }
      },
      series: [
        {
          name: '效能画像',
          type: 'radar',
          data: [
            {
              value: data.current_values || [92, 96, 88, 94, 90],
              name: '个人画像',
              itemStyle: { color: '#3370FF' },
              areaStyle: { color: 'rgba(51, 112, 255, 0.22)' }
            },
            {
              value: data.team_avg_values || [86, 89, 82, 88, 84],
              name: '团队均值',
              itemStyle: { color: '#8F959E' },
              areaStyle: { color: 'rgba(143, 149, 158, 0.12)' }
            }
          ]
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

defineExpose({ renderRadar, resize })

onMounted(() => {
  renderRadar()
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
.radar-card {
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

.radar-box {
  width: 100%;
  height: 340px;
}
</style>
