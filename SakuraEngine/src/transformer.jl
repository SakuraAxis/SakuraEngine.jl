#= 
transformer.jl — Directive transformation layer
Responsible for converting directive attributes ( sk-* / v-* ) on ElementNode into corresponding AST control nodes ( ForNode / IfNode ).
=#

# Supported for directive keys ( priority from high to low )
const FOR_DIRECTIVES = ("sk-for", "v-for")

# Supported if directive keys
const IF_DIRECTIVES  = ("sk-if", "v-if")

"""
    _parse_for_expr(expr) -> (var::Symbol, iterable)

Parse for expressions in the format `item in items` or `(idx, item) in items`.
"""
function _parse_for_expr(expr::AbstractString)
    parts = split(expr, " in ", limit=2)
    length(parts) != 2 &&
        error("SakuraEngine [Transformer] : Invalid for expression `$expr`, format should be `item in iterable`")

    var_str = strip(parts[1])
    iterable_str = strip(parts[2])

    var = Symbol(var_str)
    iterable = try
        Meta.parse(iterable_str)
    catch e
        error("SakuraEngine [Transformer] : for expression iterable parsing failed `$iterable_str` - $e")
    end

    return var, iterable
end

"""
    _parse_if_expr(expr) -> Expr

Parse the conditional expression string and return it to Julia Expr.
"""
function _parse_if_expr(expr::AbstractString)
    try
        Meta.parse(strip(expr))
    catch e
        error("SakuraEngine [Transformer] : if expression parsing failed `$expr` - $e")
    end
end

"""
    _find_directive(attrs, keys) -> (key, value) | nothing

Find the first matching directive in the attribute dictionary according to priority.
"""
function _find_directive(attrs::Dict{String,String}, keys)
    for k in keys
        haskey(attrs, k) && return (k, attrs[k])
    end
    return nothing
end

"""
    transform_directives(nodes) -> Vector{Node}

Recursively convert directive attributes on ElementNode into control nodes.
Processing priority : for > if ( for wraps the entire node, if is inside )
"""
function transform_directives(nodes::Vector{Node})
    new_nodes = Node[]

    for node in nodes
        if !(node isa ElementNode)
            push!(new_nodes, node)
            continue
        end

        # Recursively process child nodes
        node = ElementNode(
            node.tag,
            node.attrs,
            transform_directives(node.children)
        )

        # sk-for / v-for priority ( it will wrap the entire node )
        for_directive = _find_directive(node.attrs, FOR_DIRECTIVES)
        if for_directive !== nothing
            dir_key, dir_val = for_directive
            var, iterable = _parse_for_expr(dir_val)

            clean_attrs = copy(node.attrs)
            delete!(clean_attrs, dir_key)
            clean_node = ElementNode(node.tag, clean_attrs, node.children)

            push!(new_nodes, ForNode(var, iterable, [clean_node]))
            continue
        end

        # sk-if / v-if
        if_directive = _find_directive(node.attrs, IF_DIRECTIVES)
        if if_directive !== nothing
            dir_key, dir_val = if_directive
            cond_expr = _parse_if_expr(dir_val)

            clean_attrs = copy(node.attrs)
            delete!(clean_attrs, dir_key)
            clean_node = ElementNode(node.tag, clean_attrs, node.children)

            push!(new_nodes, IfNode(cond_expr, [clean_node]))
            continue
        end

        push!(new_nodes, node)
    end

    return new_nodes
end
