<template>
  <div class="glass-card worklog-form-card">
    <div class="card-header">
      <div class="card-title">
        <span class="accent-bar"></span>
        <span>快速填报今日工作日志</span>
      </div>
      <span class="badge badge-primary">{{ todayStr }}</span>
    </div>

    <form @submit.prevent="handleSubmit" class="form-content">
      <div class="form-row-2">
        <div class="form-group">
          <label class="form-label">日志归属日期</label>
          <input v-model="form.log_date" type="date" class="form-input" required />
        </div>
        <div class="form-group">
          <label class="form-label">实际总工时 (h)</label>
          <input v-model.number="form.spent_hours" type="number" step="0.5" min="1" max="24" class="form-input" required />
        </div>
      </div>

      <div class="form-group">
        <label class="form-label">所属工程项目</label>
        <select v-model="form.project_id" class="form-select">
          <option :value="null">通用任务 / 无特定项目绑定</option>
          <option v-for="p in projects" :key="p.id" :value="p.id">{{ p.name }} ({{ p.code }})</option>
        </select>
      </div>

      <div class="form-group">
        <label class="form-label">工作产出与攻坚记录</label>
        <textarea 
          v-model="form.content_json.task" 
          class="form-textarea" 
          rows="3" 
          placeholder="详细列出今日完成的核心研发、测试或架构攻坚工作..."
          required
        ></textarea>
      </div>

      <div class="form-group">
        <label class="form-label">技术阻碍与难点 (可选，汇入卡点看板)</label>
        <input 
          v-model="form.content_json.blockers" 
          class="form-input" 
          placeholder="例如：数据库连接池偶发心跳丢失，正在增加 pre-ping 探测"
        />
      </div>

      <div class="form-group">
        <label class="form-label">明日工作计划</label>
        <input 
          v-model="form.content_json.tomorrow_plan" 
          class="form-input" 
          placeholder="简述次日重点推进事项"
        />
      </div>

      <div class="form-actions">
        <button type="submit" class="btn btn-primary" :disabled="submitting">
          {{ submitting ? '正在提交...' : '保存并提交今日日志' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { createWorkLogApi } from '../../api/workLogs'

const props = defineProps({
  projects: {
    type: Array,
    default: () => []
  },
  templates: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['submitted'])

const todayStr = new Date().toISOString().slice(0, 10)
const submitting = ref(false)

const form = reactive({
  template_id: 1,
  project_id: null,
  log_date: todayStr,
  spent_hours: 8.0,
  content_json: {
    task: '',
    blockers: '',
    tomorrow_plan: ''
  },
  tag_ids: []
})

const handleSubmit = async () => {
  submitting.value = true
  try {
    await createWorkLogApi(form)
    form.content_json.task = ''
    form.content_json.blockers = ''
    form.content_json.tomorrow_plan = ''
    emit('submitted')
  } catch (err) {
    alert(err.message)
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.worklog-form-card {
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

.form-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.form-row-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 12px;
  font-weight: 500;
  color: var(--text-main);
}

.form-input, .form-select, .form-textarea {
  width: 100%;
  background: #FFFFFF;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  padding: 8px 12px;
  font-size: 13px;
  font-family: var(--font-sans);
  color: var(--text-main);
  outline: none;
  transition: all 0.15s ease;
}

.form-input:focus, .form-select:focus, .form-textarea:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px rgba(51, 112, 255, 0.15);
}

.form-actions {
  margin-top: 4px;
  display: flex;
  justify-content: flex-end;
}
</style>
