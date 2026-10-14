import request from './request'

export const loginApi = (username, password) => {
  return request.post('/auth/login', { username, password })
}

export const getMyProfileApi = () => {
  return request.get('/auth/me')
}

export const refreshTokenApi = (refresh_token) => {
  return request.post('/auth/refresh', { refresh_token })
}

export const changePasswordApi = (old_password, new_password) => {
  return request.post('/auth/change-password', { old_password, new_password })
}

export const logoutApi = () => {
  return request.post('/auth/logout')
}
