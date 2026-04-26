import { readFileSync, writeFileSync } from 'node:fs'
import { renderVuePanel } from '../src/entry-server'
import type { SkPanelState } from '../src/app'

const args = process.argv.slice(2)
const stateFlagIndex = args.indexOf('--state')
const outFlagIndex = args.indexOf('--out')

if (stateFlagIndex === -1 || stateFlagIndex === args.length - 1) {
  console.error('Usage : npm run render:panel -- --state <path-to-json> [--out <path-to-html>]')
  process.exit(1)
}

const statePath = args[stateFlagIndex + 1]
const outPath = outFlagIndex !== -1 && outFlagIndex < args.length - 1 ? args[outFlagIndex + 1] : null
const raw = readFileSync(statePath, 'utf8')
const state = JSON.parse(raw) as Partial<SkPanelState>

const html = await renderVuePanel(state)

if (outPath) {
  writeFileSync(outPath, html)
} else {
  process.stdout.write(html)
}
