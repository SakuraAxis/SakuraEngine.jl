#=
ast.jl - AST Node Type Definitions
All parsed template nodes are represented by these structs
=#

abstract type Node end

# Pure text node ( without interpolation )
struct TextNode <: Node
    content::String
end

# {{ expr }} Interpolation node
struct InterpNode <: Node
    expr::Union{Expr, Symbol, Number}
end

# sk-if / v-if Conditional node
struct IfNode <: Node
    cond::Any
    children::Vector{Node}
end

# General HTML element node
struct ElementNode <: Node
    tag::String
    attrs::Dict{String,String}
    children::Vector{Node}
end

# sk-for / v-for Loop node
struct ForNode <: Node
    var::Symbol
    iterable::Any
    children::Vector{Node}
end
