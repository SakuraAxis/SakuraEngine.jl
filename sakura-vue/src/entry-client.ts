import { createSkPanelApp, type SkPanelState } from './app'
import './style.css'

const mountNode = document.getElementById('vue-panel')
const stateNode = document.getElementById('sk-hydration-state')

if (mountNode && stateNode) {
  const initialState = JSON.parse(stateNode.textContent || '{}') as Partial<SkPanelState>
  createSkPanelApp(initialState).mount(mountNode)
}
