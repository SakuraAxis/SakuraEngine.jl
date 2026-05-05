function highlight_sk(filename::String)
    if !isfile(filename)
        error("File not found: $filename")
    end

    content = read(filename, String)

    # Color Configuration ( ANSI TrueColor )
    sk_tags = Dict(
        "sk-script"   => "\033[38;2;149;88;178m",
        "sk-template" => "\033[38;2;149;88;178m",
    )
    sk_attr_color = "\033[38;2;255;242;184m"
    sk_attrs = Dict(
        "sk-if"      => sk_attr_color,
        "sk-else-if" => sk_attr_color,
        "sk-else"    => sk_attr_color,
        "sk-on"      => sk_attr_color,
        "sk-for"     => sk_attr_color,
        "sk-bind"    => sk_attr_color,
        "sk-model"   => sk_attr_color,
        "sk-show"    => sk_attr_color,
    )
    vue_attr_color = "\033[38;2;186;255;205m"
    vue_shorthand_attr_color = "\033[38;2;198;255;140m"
    vue_attrs = Dict(
        "v-if"      => vue_attr_color,
        "v-else-if" => vue_attr_color,
        "v-else"    => vue_attr_color,
        "v-for"     => vue_attr_color,
        "v-bind"    => vue_attr_color,
        "v-on"      => vue_attr_color,
        "v-model"   => vue_attr_color,
        "v-show"    => vue_attr_color,
        "v-html"    => vue_attr_color,
        "v-text"    => vue_attr_color,
        "v-slot"    => vue_attr_color,
        "v-pre"     => vue_attr_color,
        "v-cloak"   => vue_attr_color,
        "v-once"    => vue_attr_color,
        "v-memo"    => vue_attr_color,
    )
    theme = Dict(
        :expression          => "\033[38;2;255;117;239m",
        :expression_computed => "\033[38;2;255;150;201m",
        :html_tag            => "\033[38;2;255;156;207m",
        :html_tag_name       => "\033[38;2;255;178;41m",
        :html_attr_class     => "\033[38;2;153;142;124m",
        :html_attr_value     => "\033[38;2;224;190;232m",
        :delimiter           => "\033[38;2;200;167;252m",
        :sk_script_body      => "\033[38;2;180;180;180m",
        :title               => "\033[1;37m",
        :comment             => "\033[38;2;135;206;235m",
    )
    reset = "\033[0m"

    sk_tag_pattern  = join(keys(sk_tags),  "|")
    sk_attr_pattern = join(keys(sk_attrs), "|")
    vue_attr_pattern = join(keys(vue_attrs), "|")

    # helpers

    # Highlight {{|| expr ||}} and {{ expr }} inside an already-extracted string
    function highlight_expressions(s::AbstractString)
        s = replace(String(s), r"\{\{\|\|.*?\|\|\}\}"s => sub -> begin
            sub = String(sub)
            inner = sub[5:end-4]
            has_op = occursin(r"[+\-*/%&|=!><]", inner)
            color = has_op ? theme[:expression_computed] : theme[:expression]
            theme[:delimiter] * "{{" * reset *
            color * "||" * inner * "||" * reset *
            theme[:delimiter] * "}}" * reset
        end)

        replace(s, r"\{\{(?!\|\|).*?\}\}"s => sub -> begin
            sub = String(sub)
            inner = sub[3:end-2]
            theme[:delimiter] * "{{" * reset *
            theme[:delimiter] * inner * reset *
            theme[:delimiter] * "}}" * reset
        end)
    end

    # Highlight sk-* and class= attributes inside an attr string
    function highlight_attrs(attr_part::AbstractString)
        # a. sk-* attributes ( supports optional suffixes like sk-bind:href )
        attr_name_re = "($(sk_attr_pattern))(?:\\:[A-Za-z_][A-Za-z0-9_\\-]*)?"
        processed = replace(String(attr_part),
            Regex("($attr_name_re)(\\s*=\\s*\"[^\"]*\")?", "i") => a -> begin
                a = String(a)
                am = match(Regex("($(sk_attr_pattern))", "i"), a)
                am === nothing && return a
                color = get(sk_attrs, lowercase(String(am[1])), theme[:html_tag])
                color * a * reset
            end)

        # b. Vue attributes ( v-bind:href, v-on:click, v-slot )
        vue_attr_name_re = "\\b(?:$(vue_attr_pattern))(?:[:.][A-Za-z_][A-Za-z0-9_\\-]*)*"
        processed = replace(processed,
            Regex("($vue_attr_name_re)(\\s*=\\s*(?:\"[^\"]*\"|'[^']*'|[^\\s>]+))?", "i") => a -> begin
                a = String(a)
                vue_attr_color * a * reset
            end)

        # c. Vue shorthand attributes ( :href, @click, #default )
        vue_shorthand_attr_name_re = "[:@#][A-Za-z_][A-Za-z0-9_:\\-]*(?:\\.[A-Za-z_][A-Za-z0-9_\\-]*)*"
        processed = replace(processed,
            Regex("($vue_shorthand_attr_name_re)(\\s*=\\s*(?:\"[^\"]*\"|'[^']*'|[^\\s>]+))?", "i") => a -> begin
                a = String(a)
                vue_shorthand_attr_color * a * reset
            end)

        # d. class= attribute
        processed = replace(processed,
            r"(class\s*=\s*[\"'])([^\"']*)([\"'])"i => c -> begin
                c = String(c)
                cm = match(r"(class\s*=\s*[\"'])([^\"']*)([\"'])"i, c)
                cm === nothing && return c
                theme[:html_attr_class] * String(cm[1]) * reset *
                theme[:html_attr_value] * String(cm[2]) * reset *
                theme[:html_attr_class] * String(cm[3]) * reset
            end)

        processed
    end

    # Split content into segments : script-like blocks vs everything else

    #=
    Strategy : tokenise the file into a list of ( kind, text ) pairs, then
    process each kind independently so TypeScript generics such as ref<string>
    are never mistaken for HTML tags.
    =#

    segments = Tuple{Symbol,String}[]

    # Regex that captures script-like blocks ( multiline )
    script_block_re = r"(<sk-script(?:\s(?:\"[^\"]*\"|'[^']*'|[^>])*)?>)(.*?)(</sk-script>)|(<script(?:\s(?:\"[^\"]*\"|'[^']*'|[^>])*)?>)(.*?)(</script>)"si

    pos = 1
    for m in eachmatch(script_block_re, content)
        # text before this block
        if m.offset > pos
            push!(segments, (:html, content[pos : m.offset - 1]))
        end

        if m.captures[1] !== nothing
            push!(segments, (:sk_open, String(m.captures[1]))) # <sk-script>
            push!(segments, (:sk_body, String(m.captures[2]))) # raw Julia content
            push!(segments, (:sk_close, String(m.captures[3]))) # </sk-script>
        else
            push!(segments, (:script_open, String(m.captures[4]))) # <script>
            push!(segments, (:script_body, String(m.captures[5]))) # raw JS/TS content
            push!(segments, (:script_close, String(m.captures[6]))) # </script>
        end

        pos = m.offset + length(m.match)
    end
    # remainder
    if pos <= lastindex(content)
        push!(segments, (:html, content[pos:end]))
    end

    # Process each segment

    function process_html(s::AbstractString)
        # 1. Sakura container tags : <sk-template> </sk-template> etc
        s = replace(String(s),
            Regex("(</?)($(sk_tag_pattern))((?:\"[^\"]*\"|'[^']*'|[^>])*>)", "si") => sub -> begin
                sub = String(sub)
                mm = match(Regex("(</?)($(sk_tag_pattern))((?:\"[^\"]*\"|'[^']*'|[^>])*>)", "si"), sub)
                mm === nothing && return sub
                tag_color = get(sk_tags, lowercase(String(mm[2])), theme[:html_tag])
                tag_color * sub * reset
            end)

        # 2. Expressions {{|| ... ||}}
        s = highlight_expressions(s)

        # 3. Standard HTML tags — quote-aware attr matching
        #=
        Attr part: (?:"[^"]*"|'[^']*'|[^>])*
        This alternation consumes quoted strings whole (so > inside quotes
        is never mistaken for the closing >), and falls back to any
        non-> character otherwise. The first unquoted > ends the tag
        =#
        s = replace(s,
            r"(<(?!/?sk-)/?[a-zA-Z][a-zA-Z0-9-]*)((?:\"[^\"]*\"|'[^']*'|[^>])*)(>)"s => sub -> begin
                sub = String(sub)
                mm = match(r"(<(?!/?sk-)/?[a-zA-Z][a-zA-Z0-9-]*)((?:\"[^\"]*\"|'[^']*'|[^>])*)(>)"s, sub)
                mm === nothing && return sub
                tag_part  = String(mm[1])
                attr_part = highlight_attrs(String(mm[2]))
                tail_part = String(mm[3])
                theme[:html_tag_name] * tag_part * reset *
                attr_part *
                theme[:html_tag_name] * tail_part * reset
            end)

        # 4. Comments #= ... =# and <!-- ... -->
        s = replace(s, r"(#=.*?=#|<!--.*?-->)"s => sub -> begin
            clean_sub = replace(String(sub), r"\033\[[0-9;]*m" => "")
            theme[:comment] * clean_sub * reset
        end)

        s
    end

    function process_sk_open(s::AbstractString)
        # The opening <sk-script> tag itself
        tag_color = get(sk_tags, "sk-script", theme[:html_tag])
        tag_color * s * reset
    end

    function process_sk_body(s::AbstractString)
        # Raw Julia/script body — just dim it, no HTML processing
        theme[:sk_script_body] * s * reset
    end

    function process_sk_close(s::AbstractString)
        tag_color = get(sk_tags, "sk-script", theme[:html_tag])
        tag_color * s * reset
    end

    function process_script_open(s::AbstractString)
        process_html(s)
    end

    function process_script_body(s::AbstractString)
        highlight_expressions(s)
    end

    function process_script_close(s::AbstractString)
        process_html(s)
    end

    highlighted = join(
        map(segments) do (kind, text)
            if     kind === :html         ; process_html(text)
            elseif kind === :sk_open      ; process_sk_open(text)
            elseif kind === :sk_body      ; process_sk_body(text)
            elseif kind === :sk_close     ; process_sk_close(text)
            elseif kind === :script_open  ; process_script_open(text)
            elseif kind === :script_body  ; process_script_body(text)
            elseif kind === :script_close ; process_script_close(text)
            else                          ; text
            end
        end
    )

    # Output
    println(theme[:title] * "|||||| SK Template Highlight: $filename ||||||" * reset * "\n")
    print(highlighted)
    println("\n\n" * theme[:title] * "|||||| End of File ||||||" * reset)
end

# CLI Entry Point
if !isempty(ARGS)
    highlight_sk(ARGS[1])
else
    println("Usage : julia --project=. --color=yes scripts/highlight_sk.jl template_example/hydration_example.sk")
end
