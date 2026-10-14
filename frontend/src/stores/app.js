import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAppStore = defineStore('app', () => {
  // 当前激活的文房四宝视口：bi (笔), zhi (纸), mo (墨), yan (砚)
  const currentTab = ref('bi')

  const setTab = (tab) => {
    currentTab.value = tab
  }

  return {
    currentTab,
    setTab
  }
})
