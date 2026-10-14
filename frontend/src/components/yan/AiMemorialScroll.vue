<template>
  <div class="glass-card ai-console-card">
    <div class="console-header">
      <div class="console-title">
        <span class="accent-bar"></span>
        <span>AI 智能研发推演中枢 (SSE 实时流式控制台)</span>
      </div>
      <div class="quick-prompts">
        <button @click="setPrompt('针对近期后端数据库连接池超时与跨域拦截，请给出详细攻坚排查方案与预防策略')" class="prompt-chip">
          排查方案推演
        </button>
        <button @click="setPrompt('请根据当前研发进度与工时投入，推演下一迭代的核心交付风险与人员调配建议')" class="prompt-chip">
          迭代风险预测
        </button>
        <button @click="setPrompt('请针对团队新成员开展敏捷日志规范与KISS复盘方法论培训指导')" class="prompt-chip">
          KISS培训指南
        </button>
      </div>
    </div>

    <!-- 输入指令栏 -->
    <div class="stream-input-wrap">
      <textarea 
        v-model="promptInput" 
        class="form-textarea" 
        rows="2" 
        placeholder="向 AI 智能中枢输入推演指令或研发提问..."
        :disabled="isStreaming"
      ></textarea>
      <button 
        @click="handleStartStreaming" 
        class="btn btn-primary stream-btn"
        :disabled="isStreaming || !promptInput.trim()"
      >
        <span v-if="isStreaming">正在流式推演...</span>
        <span v-else>执行流式推演</span>
      </button>
    </div>

    <!-- 流式终端屏幕 -->
    <div class="terminal-screen">
      <div class="terminal-top">
        <div class="terminal-dots">
          <span class="t-dot dot-red"></span>
          <span class="t-dot dot-yellow"></span>
          <span class="t-dot dot-green"></span>
        </div>
        <div class="terminal-title">AI ENGINE SSE STREAM CONSOLE</div>
      </div>
      <div class="terminal-body" ref="terminalBodyRef">
        <div v-if="!streamOutput && !isStreaming" class="terminal-placeholder">
          等待发送推演指令... 控制台将以打字机流式字符实时输出深度推演成果。
        </div>
        <div class="terminal-text">{{ streamOutput }}<span v-if="isStreaming" class="cursor-blink">|</span></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, onUnmounted } from 'vue'

const emit = defineEmits(['stream-complete'])

const promptInput = ref('针对近期后端数据库连接池超时与跨域拦截，请给出详细攻坚排查方案与预防策略')
const streamOutput = ref('')
const isStreaming = ref(false)
const terminalBodyRef = ref(null)

let abortController = null
let isComponentUnmounted = false

onUnmounted(() => {
  isComponentUnmounted = true
  if (abortController) {
    abortController.abort()
    abortController = null
  }
})

const setPrompt = (txt) => {
  promptInput.value = txt
}

const handleStartStreaming = async () => {
  if (!promptInput.value.trim() || isStreaming.value) return
  isStreaming.value = true
  streamOutput.value = ''

  if (abortController) {
    abortController.abort()
  }
  abortController = new AbortController()

  try {
    const response = await fetch('/api/v1/ai/stream', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('end_design_token') || ''}`
      },
      body: JSON.stringify({ prompt: promptInput.value }),
      signal: abortController.signal
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }

    const reader = response.body.getReader()
    const decoder = new TextDecoder('utf-8')
    let buffer = ''

    while (true) {
      if (isComponentUnmounted) {
        reader.cancel()
        break
      }
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })
      const lines = buffer.split('\n\n')
      buffer = lines.pop()

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const raw = line.slice(6).trim()
          if (raw === '[DONE]') {
            isStreaming.value = false
            break
          }
          try {
            const parsed = JSON.parse(raw)
            if (parsed.chunk && !isComponentUnmounted) {
              streamOutput.value += parsed.chunk
              nextTick(() => {
                if (terminalBodyRef.value) {
                  terminalBodyRef.value.scrollTop = terminalBodyRef.value.scrollHeight
                }
              })
            }
          } catch (err) {
            // ignore
          }
        }
      }
    }
  } catch (e) {
    if (e.name !== 'AbortError' && !isComponentUnmounted) {
      streamOutput.value += `\n[系统异常] 流式连接中断：${e.message}`
    }
  } finally {
    if (!isComponentUnmounted) {
      isStreaming.value = false
      emit('stream-complete')
    }
    abortController = null
  }
}
</script>

<style scoped>
.console-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  flex-wrap: wrap;
  gap: 12px;
}

.console-title {
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

.quick-prompts {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.prompt-chip {
  background: var(--bg-subtle);
  border: 1px solid var(--border-color);
  color: var(--text-main);
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.15s ease;
  font-family: var(--font-sans);
}

.prompt-chip:hover {
  background: var(--primary-light);
  color: var(--primary);
  border-color: var(--primary);
}

.stream-input-wrap {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 16px;
}

@media (min-width: 640px) {
  .stream-input-wrap {
    flex-direction: row;
    align-items: flex-start;
  }
  .stream-btn {
    white-space: nowrap;
    height: 56px;
  }
}

.terminal-screen {
  background: #18191C;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #2B2F36;
}

.terminal-top {
  background: #23272E;
  padding: 8px 14px;
  display: flex;
  align-items: center;
  border-bottom: 1px solid #2B2F36;
}

.terminal-dots {
  display: flex;
  gap: 6px;
}

.t-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.dot-red { background: #FF5F56; }
.dot-yellow { background: #FFBD2E; }
.dot-green { background: #27C93F; }

.terminal-title {
  margin-left: 14px;
  font-size: 11px;
  font-family: var(--font-mono);
  color: #8F959E;
  letter-spacing: 0.05em;
}

.terminal-body {
  padding: 16px 20px;
  min-height: 220px;
  max-height: 400px;
  overflow-y: auto;
  font-family: var(--font-mono);
  font-size: 13px;
  line-height: 1.7;
  color: #E6E8EB;
}

.terminal-placeholder {
  color: #646A73;
  font-style: italic;
}

.terminal-text {
  white-space: pre-wrap;
}

.cursor-blink {
  animation: blink 0.8s infinite;
  color: var(--primary);
  font-weight: 700;
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}
</style>
