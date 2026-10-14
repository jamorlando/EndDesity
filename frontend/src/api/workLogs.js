import request from './request'

export const getWorkLogsApi = (params) => {
  return request.get('/work-logs', { params })
}

export const getWorkLogDetailApi = (id) => {
  return request.get(`/work-logs/${id}`)
}

export const createWorkLogApi = (data) => {
  return request.post('/work-logs', data)
}

export const updateWorkLogApi = (id, data) => {
  return request.put(`/work-logs/${id}`, data)
}

export const rollbackWorkLogApi = (id, data) => {
  return request.post(`/work-logs/${id}/rollback`, data)
}

export const addCommentApi = (id, data) => {
  return request.post(`/work-logs/${id}/comments`, data)
}

export const scoreWorkLogApi = (id, score) => {
  return request.post(`/work-logs/${id}/score`, { score })
}

export const getTemplatesApi = () => {
  return request.get('/work-logs/templates')
}

export const getTagsApi = () => {
  return request.get('/work-logs/tags')
}

export const getCalendarHeatmapApi = (params) => {
  return request.get('/work-logs/calendar-heatmap', { params })
}

export const getBlockersApi = (params) => {
  return request.get('/work-logs/blockers', { params })
}
