import request from './request'

export const getAiModelsApi = () => {
  return request.get('/ai/models')
}

export const getLlmCallLogsApi = (limit = 20) => {
  return request.get('/ai/call-logs', { params: { limit } })
}
