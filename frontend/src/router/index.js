import { createRouter, createWebHistory } from 'vue-router'
import AppLayout from '../components/layout/AppLayout.vue'
import LoginView from '../views/login/LoginView.vue'
import WorkLogView from '../views/bi/WorkLogView.vue'
import RetroView from '../views/zhi/RetroView.vue'
import StatsView from '../views/mo/StatsView.vue'
import AiGatewayView from '../views/yan/AiGatewayView.vue'
import ProjectsView from '../views/projects/ProjectsView.vue'
import TeamsView from '../views/teams/TeamsView.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: LoginView,
    meta: { public: true }
  },
  {
    path: '/',
    component: AppLayout,
    redirect: '/bi',
    children: [
      {
        path: 'bi',
        name: 'WorkLog',
        component: WorkLogView,
        meta: { tab: 'bi', title: '笔墨丹青 · 日志与工时中心' }
      },
      {
        path: 'zhi',
        name: 'Retro',
        component: RetroView,
        meta: { tab: 'zhi', title: '澄心堂纸 · 智能复盘与闭环' }
      },
      {
        path: 'mo',
        name: 'Stats',
        component: StatsView,
        meta: { tab: 'mo', title: '松烟墨韵 · 研发效能全景大屏' }
      },
      {
        path: 'yan',
        name: 'AiGateway',
        component: AiGatewayView,
        meta: { tab: 'yan', title: '端溪古砚 · AI 智能底座网关' }
      },
      {
        path: 'projects',
        name: 'Projects',
        component: ProjectsView,
        meta: { tab: 'projects', title: '企业项目与交付管理' }
      },
      {
        path: 'teams',
        name: 'Teams',
        component: TeamsView,
        meta: { tab: 'teams', title: '组织架构与团队方阵' }
      }
    ]
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/bi'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫：登录凭证鉴权拦截
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('end_design_token')
  if (!to.meta.public && !token) {
    next({ name: 'Login' })
  } else if (to.name === 'Login' && token) {
    next({ path: '/bi' })
  } else {
    next()
  }
})

export default router
