import axios from 'axios'

const instance = axios.create({
  baseURL: '/api/v1',
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器：自动注入 Bearer Token
instance.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('end_design_token')
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// 响应拦截器：统一解包与错误提示
instance.interceptors.response.use(
  (response) => {
    const res = response.data
    // 如果返回符合标准结构
    if (res && typeof res.code !== 'undefined') {
      if (res.code === 200 || res.code === 201) {
        return res.data
      }
      const msg = res.message || '系统业务处理异常'
      console.error('API Error:', msg)
      return Promise.reject(new Error(msg))
    }
    return res
  },
  (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('end_design_token')
      localStorage.removeItem('end_design_user')
      if (!window.location.pathname.includes('/login')) {
        window.location.href = '/login'
      }
    }
    const errorMsg = error.response?.data?.detail || error.response?.data?.message || error.message || '网络通信异常'
    return Promise.reject(new Error(errorMsg))
  }
)

export default instance
