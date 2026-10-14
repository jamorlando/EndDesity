import request from './request'

export const getReportsApi = (params) => {
  return request.get('/retrospectives', { params })
}

export const getReportDetailApi = (id) => {
  return request.get(`/retrospectives/${id}`)
}

export const createReportApi = (data) => {
  return request.post('/retrospectives', data)
}

export const updateReportApi = (id, data) => {
  return request.put(`/retrospectives/${id}`, data)
}

export const getActionItemsApi = (params) => {
  return request.get('/retrospectives/action-items', { params })
}

export const updateActionItemApi = (id, data) => {
  return request.put(`/retrospectives/action-items/${id}`, data)
}
