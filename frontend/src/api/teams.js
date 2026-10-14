import request from './request'

export const getTeamsApi = () => {
  return request.get('/teams')
}

export const getTeamDetailApi = (id) => {
  return request.get(`/teams/${id}`)
}

export const createTeamApi = (data) => {
  return request.post('/teams', data)
}

export const updateTeamApi = (id, data) => {
  return request.put(`/teams/${id}`, data)
}
