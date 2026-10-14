import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { loginApi, getMyProfileApi, logoutApi } from '../api/auth'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('end_design_token') || '')
  const user = ref(JSON.parse(localStorage.getItem('end_design_user') || 'null'))

  const isLoggedIn = computed(() => !!token.value)
  const isRoot = computed(() => user.value?.is_root === 1 || user.value?.role === 'SUPER_ADMIN')
  const isLeader = computed(() => user.value?.role === 'TEAM_LEADER' || isRoot.value)
  const isMember = computed(() => user.value?.role === 'MEMBER')

  const setAuth = (newToken, newUser) => {
    token.value = newToken
    user.value = newUser
    localStorage.setItem('end_design_token', newToken)
    localStorage.setItem('end_design_user', JSON.stringify(newUser))
  }

  const login = async (username, password) => {
    const res = await loginApi(username, password)
    setAuth(res.access_token, res.user)
    return res
  }

  const fetchProfile = async () => {
    if (!token.value) return null
    try {
      const profile = await getMyProfileApi()
      user.value = profile
      localStorage.setItem('end_design_user', JSON.stringify(profile))
      return profile
    } catch (e) {
      logout()
      return null
    }
  }

  const logout = async () => {
    try {
      if (token.value) await logoutApi()
    } catch (e) {
      // ignore
    } finally {
      token.value = ''
      user.value = null
      localStorage.removeItem('end_design_token')
      localStorage.removeItem('end_design_user')
    }
  }

  return {
    token,
    user,
    isLoggedIn,
    isRoot,
    isLeader,
    isMember,
    login,
    fetchProfile,
    logout
  }
})
