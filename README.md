# SakuraEngine.jl

![GitHub last commit](https://img.shields.io/github/last-commit/zzztzzzt/SakuraEngine.jl.svg)
![GitHub repo size](https://img.shields.io/github/repo-size/zzztzzzt/SakuraEngine.jl.svg)

<br>

<img src="https://github.com/zzztzzzt/SakuraEngine.jl/blob/main/logo/logo.png" alt="sakura-engine-logo" style="height: 280px; width: auto;" />

### SakuraEngine - Julia SSR Template Engine with Vue Hydration.

IMPORTANT : This project is still in the development and testing stages, licensing terms may be updated in the future. Please don't do any commercial usage currently.

## Project Dependencies Guide

[![Julia](https://img.shields.io/badge/Julia-9558B2?style=for-the-badge&logo=julia&logoColor=white)](https://github.com/JuliaLang/julia)
[![Vue3](https://img.shields.io/badge/vue3-4FC08D?style=for-the-badge&logo=vuedotjs&logoColor=white)](https://github.com/vuejs/core)
[![Tailwind CSS](https://img.shields.io/badge/tailwind_css-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white)](https://github.com/tailwindlabs/tailwindcss)
[![vite](https://img.shields.io/badge/vite-646CFF?style=for-the-badge&logo=vite&logoColor=white)](https://github.com/vitejs/vite)

## WIP Project SakuraEngine

### SK Template Example

```html
#= Julia script =#
<sk-script>
x = 10
name = "Sakura"
score = 72

items = [1, 2, 3]

dynamic_url = "https://juliahub.com/"
is_disabled = true
dict_items = Dict("A" => 100, "B" => 200)
</sk-script>

<sk-template>
<div>
  <p>Hello {{|| name ||}}</p>
  <p>{{|| x + 5 ||}}</p>
</div>

#= sk-if / sk-else-if / sk-else chain =#
<div>
  <p sk-if="score >= 90">
    Grade A - Excellent!
  </p>
  <p sk-else-if="score >= 75">
    Grade B - Good.
  </p>
  <p sk-else-if="score >= 60">
    Grade C - Pass.
  </p>
  <p sk-else>
    Grade F - Failed.
  </p>
</div>

#= sk-for + nested sk-if / sk-else =#
<ul>
  <li sk-for="item in items">
    <span sk-if="item > 2">
      {{|| item ||}} - big
    </span>
    <span sk-else-if="item == 2">
      {{|| item ||}} - medium
    </span>
    <span sk-else>
      {{|| item ||}} - small
    </span>
  </li>
</ul>

#= sk-for with tuple destructuring =#
<ul>
  <li sk-for="(k, v) in dict_items">
    {{|| k ||}} : {{|| v ||}}
  </li>
</ul>

#= sk-bind =#
<div>
  <a
    sk-bind:href="dynamic_url"
    sk-bind:disabled="is_disabled"
    class="btn"
  >
    Click Me
  </a>
</div>
</sk-template>
```

## Project Detail / Debug

### Currently Run Below To Test

```shell
julia --project=. scripts/render_hydration_example.jl
```

### Current Mixed Template Rules

SakuraEngine uses a two-phase template pipeline for Vue 3 style hydration :

1. Server phase :
   `sk-if`, `sk-else-if`, `sk-else`, `sk-for`, `sk-bind:*`, and `{{|| expr ||}}`
   are executed by SakuraEngine on the server first.
2. Client phase :
   Vue directives and Vue interpolation such as `v-if`, `v-else-if`, `v-else`,
   `v-for`, `v-model`, `@click`, `:prop`, and `{{ expr }}` are preserved in the
   rendered HTML for Vue 3 to process on the client.

Top-level sibling blocks are also allowed :

- `<sk-script>` provides Julia server context
- `<script type="application/json">` and `<script type="module">` may live at
  the same level as `<sk-template>`
- top-level sibling scripts are preserved in output
- `{{|| expr ||}}` inside those sibling scripts is rendered by SakuraEngine
- Vue syntax inside sibling scripts is left untouched

### Directive Ownership

- `{{|| expr ||}}` is server interpolation only.
- `{{ expr }}` is Vue interpolation only.
- `sk-*` directives own the server structural pass.
- `v-*` directives own the client reactive pass.

### Execution Order

- `sk-for` runs before `sk-if`, matching the current transformer priority.
- After SakuraEngine expands or removes nodes, the remaining template is passed
  forward with Vue syntax intact.
- This means Vue only sees the post-`sk-*` DOM shape.

### Mixing Strategy

Allowed and recommended :

- `sk-for` wrapping markup that still contains `v-if`, `v-model`, `@click`, or `{{ }}`
- `sk-if` gating a Vue-owned section
- `{{|| expr ||}}` and `{{ expr }}` in the same file, as long as each side owns
  its own data source

Use caution :

- Putting `sk-for` and `v-for` on the same element
- Putting `sk-if` and `v-if` on the same element

When both appear on the same element, SakuraEngine now keeps the Vue directive
but executes the `sk-*` directive first and emits a warning during the server
transform pass.

## Project Dependencies Details

Vue3 License : [https://github.com/vuejs/core/blob/main/LICENSE](https://github.com/vuejs/core/blob/main/LICENSE)
<br>

Tailwind CSS License : [https://github.com/tailwindlabs/tailwindcss/blob/main/LICENSE](https://github.com/tailwindlabs/tailwindcss/blob/main/LICENSE)
<br>

Vite License : [https://github.com/vitejs/vite/blob/main/LICENSE](https://github.com/vitejs/vite/blob/main/LICENSE)
