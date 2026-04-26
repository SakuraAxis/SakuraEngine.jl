using SakuraEngine

# Usage : julia --project=. scripts/test_sakura_engine.jl
html = SakuraEngine.render_file("template_example/example.sk")
hydration_html = SakuraEngine.render_file("template_example/hydration_example.sk")

@assert occursin("Hello Sakura", html)
@assert occursin(">15<", html)
@assert occursin("A : 100", html)
@assert occursin("B : 200", html)

@assert occursin("type=\"application/json\"", hydration_html)
@assert occursin("\"count\": 2", hydration_html)
@assert occursin("src=\"http://127.0.0.1:5173/src/entry-client.ts\"", hydration_html)
@assert occursin("Server Sakura / Client Sakura", hydration_html)
@assert occursin("Pending (server): 1", hydration_html)
@assert occursin("{{ user.name }}", hydration_html)
@assert occursin("tag = ssr", hydration_html)

println(html)
println("\n||||||  hydration example  ||||||\n")
println(hydration_html)
