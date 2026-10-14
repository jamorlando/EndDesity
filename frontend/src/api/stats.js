import request from './request'

export const getStatsOverviewApi = (params) => {
  return request.get('/stats/overview', { params })
}

export const getBurnDownApi = (params) => {
  return request.get('/stats/burn-down', { params })
}

export const getRadarApi = (params) => {
  return request.get('/stats/radar', { params })
}

export const getSnapshotsApi = (params) => {
  return request.get('/stats/snapshots', { params })
}
