import request from './request'

export const getProjectsApi = (params) => {
  return request.get('/projects', { params })
}

export const getProjectDetailApi = (id) => {
  return request.get(`/projects/${id}`)
}

export const createProjectApi = (data) => {
  return request.post('/projects', data)
}

export const updateProjectApi = (id, data) => {
  return request.put(`/projects/${id}`, data)
}
