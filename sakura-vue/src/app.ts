import { computed, createSSRApp, onMounted, ref } from 'vue'

export type SkTodo = {
  id: number
  label: string
  done: boolean
}

export type SkPanelState = {
  title: string
  user: { name: string }
  count: number
  todos: SkTodo[]
  serverTags: string[]
  disableIncrement: boolean
}

const template = `
<h1>{{ title }}</h1>
<p>Server {{ user.name }} / Client {{ user.name }}</p>
<p v-if="ready">Pending: {{ pending }}</p>
<p v-else>Pending (server): {{ pending }}</p>
<button :disabled="disableIncrement" @click="count++">
  Count: {{ count }}
</button>
<ul>
  <li v-for="tag in visibleTags" :key="tag">tag = {{ tag }}</li>
</ul>
<ul>
  <li v-for="todo in todos" :key="todo.id">{{ todo.label }} / owner {{ user.name }}</li>
</ul>
<p>Step now: direct hydration. Step later: bring more mixed zones into Vue SSR.</p>
`

export function normalizeState(raw: Partial<SkPanelState> | null | undefined): SkPanelState {
  return {
    title: raw?.title ?? 'Sakura + Vue 3',
    user: {
      name: raw?.user?.name ?? 'Guest',
    },
    count: raw?.count ?? 0,
    todos: raw?.todos ?? [],
    serverTags: raw?.serverTags ?? [],
    disableIncrement: raw?.disableIncrement ?? false,
  }
}

export function createSkPanelApp(raw: Partial<SkPanelState> | null | undefined) {
  const initialState = normalizeState(raw)

  return createSSRApp({
    template,
    setup() {
      const ready = ref(false)
      const title = ref(initialState.title)
      const user = ref(initialState.user)
      const count = ref(initialState.count)
      const todos = ref(initialState.todos)
      const serverTags = ref(initialState.serverTags)
      const disableIncrement = ref(initialState.disableIncrement)
      const pending = computed(() => todos.value.filter(todo => !todo.done).length)
      const visibleTags = computed(() => serverTags.value)

      onMounted(() => {
        ready.value = true
      })

      return {
        count,
        disableIncrement,
        pending,
        ready,
        serverTags,
        title,
        todos,
        user,
        visibleTags,
      }
    },
  })
}
