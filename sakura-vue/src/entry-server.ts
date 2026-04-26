import { renderToString } from '@vue/server-renderer'
import { createSkPanelApp, type SkPanelState } from './app'

export async function renderVuePanel(state: Partial<SkPanelState>) {
  const app = createSkPanelApp(state)
  return await renderToString(app)
}
