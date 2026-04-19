module SakuraEngine

export render_file, render_template

function extract_blocks(content::String)
    script_match = match(r"<sk-script>(.*?)</sk-script>"s, content)
    template_match = match(r"<sk-template>(.*?)</sk-template>"s, content)

    script = script_match !== nothing ? script_match.captures[1] : ""
    template = template_match !== nothing ? template_match.captures[1] : ""

    return script, template
end

function eval_script(script::AbstractString)
    mod = Module()
    
    # Use include_string to execute the entire string within the namespace of this module
    include_string(mod, script)

    return mod
end

function render_template(template::AbstractString, mod::Module)
    template = process_sk_if(template, mod)

    template = replace(template, r"\{\{(.*?)\}\}"s => function(m)
        # Rematch to ensure it get captures
        caps = match(r"\{\{(.*?)\}\}"s, m).captures
        clean_expr = strip(caps[1])
        
        ex = Meta.parse(clean_expr)
        val = Core.eval(mod, ex)
        return string(val)
    end)

    return template
end

function render_file(path::String)
    content = read(path, String)
    script, template = extract_blocks(content)
    mod = eval_script(script)
    html = render_template(template, mod)

    # Cleanup : Reduce multiple consecutive line breaks to one and remove lines containing only whitespace
    html = replace(html, r"\n\s*\n" => "\n")
    return strip(html)
end

function process_sk_if(template::AbstractString, mod::Module)
    pattern = r"<(\w+)([^>]*)\s+sk-if=\"(.*?)\"([^>]*)>(.*?)</\1>"s

    return replace(template, pattern => function(m)
        caps = match(pattern, m).captures
        tag = caps[1]
        before_attrs = caps[2]
        condition_str = caps[3]
        after_attrs = caps[4]
        inner = caps[5]

        # eval condition
        cond_expr = Meta.parse(condition_str)
        result = Core.eval(mod, cond_expr)

        if result
            combined_attrs = strip(string(before_attrs, " ", after_attrs))
            # If the attribute is empty, do not add a space; if there is an attribute, add a space before it
            attr_str = isempty(combined_attrs) ? "" : " " * combined_attrs
            
            return "<$tag$attr_str>$inner</$tag>"
        else
            return ""
        end
    end)
end

end # module SakuraEngine
