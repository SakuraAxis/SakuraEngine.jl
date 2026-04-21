module SakuraEngine

#=
SakuraEngine.jl — Module Entry Point

Loading Order :
ast.jl         — AST Node Type Definitions
parser.jl      — Template Parsing Layer
transformer.jl — Directive Transformation Layer (sk-* / v-*)
renderer.jl    — HTML Rendering Layer
compiler.jl    — File Loading Layer
=#

include("ast.jl")
include("parser.jl")
include("transformer.jl")
include("renderer.jl")
include("compiler.jl")

export render_file, render_template

end # module SakuraEngine