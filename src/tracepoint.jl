# This file is a part of Tracy.jl. License is MIT: See LICENSE.md


##################
# Public methods #
##################

"""
# Tracing Julia code

Code you'd like to trace should be wrapped with `@tracepoint`

    @tracepoint "name" <expression>

Typically the expression will be a `begin-end` block:

    @tracepoint "data aggregation" begin
        # lots of compute here...
    end

The name of the tracepoint must be a literal string, and it cannot
be changed at runtime.

If you don't have Tracy installed, you can install `TracyProfiler_jll`
and start it with `run(TracyProfiler_jll.tracy(); wait=false)`.

```jldoctest tracy
julia> x = rand(10,10);

julia> @tracepoint "multiply" x * x;
```

You can add a (dynamic) text to the tracepoint:

```jldoctest tracy
julia> @tracepoint "multiply text" text="\$x * \$x" x * x;
```
"""
macro tracepoint(name::String, ex...)
    ex, kws = extract_kwargs(ex)
    return _tracepoint(name, ex, __module__, string(__source__.file), __source__.line; kws...)
end

function _tracepoint(name::String, ex, mod::Module, filepath::String, line::Int; text=nothing)
    srcloc = TracySrcLoc(name, nothing, filepath, line, 0, mod, true)
    push!(meta(mod), srcloc)

    N = length(meta(mod))
    m_id = getfield(mod, ID)

    #
    text_expr = if text !== nothing
        quote
            text_eval = string($text)
            @ccall libtracy.___tracy_emit_zone_text(ctx::TracyZoneContext, text_eval::Cstring, length(text_eval)::Csize_t)::Cvoid;
        end
    else
        :()
    end

    return quote
        if tracepoint_enabled(Val($m_id), Val($N))
            if $srcloc.file == C_NULL
                initialize!($srcloc)
            end
            local ctx = @ccall libtracy.___tracy_emit_zone_begin(pointer_from_objref($srcloc)::Ptr{Cvoid},
                                                                 $srcloc.enabled::Cint)::TracyZoneContext
            $text_expr
        end
        $(Expr(:tryfinally,
            :($(esc(ex))),
            quote
                if tracepoint_enabled(Val($m_id), Val($N))
                    @ccall libtracy.___tracy_emit_zone_end(ctx::TracyZoneContext)::Cvoid
                end
            end
        ))
    end
end

"""
    configure_tracepoint

Enable/disable a set of tracepoint(s) in the provided modules by invalidating any
existing code containing the tracepoint(s).

!!! warning
    This invalidates the code generated for all functions containing the selected zones.

    This will trigger re-compilation for these functions and may cause undesirable latency.
    It is strongly recommended to use `enable_tracepoint` instead.
"""
function configure_tracepoint(m::Module, enable::Bool; name="", func="", file="")
    m_id = getfield(m, ID)
    for (i, srcloc) in enumerate(meta(m))
        contains(srcloc.name, name) || continue
        contains(srcloc.func, func) || continue
        contains(srcloc.file, file) || continue
        Core.eval(m, :($Tracy.tracepoint_enabled(::Val{$m_id}, ::Val{$i}) = $enable))
    end
    return nothing
end

"""
    enable_tracepoint

Enable/disable a set of tracepoint(s) in the provided modules, based on whether they
match the filters provided for `name`/`func`/`file`.
"""
function enable_tracepoint(m::Module, enable::Bool; name="", func="", file="")
    for srcloc in meta(m)
        contains(srcloc.name, name) || continue
        contains(srcloc.func, func) || continue
        contains(srcloc.file, file) || continue
        srcloc.enabled = enable
    end
    return nothing
end

"""
Register this module's `@tracepoint` callsites with Tracy.jl

This will allow tracepoints to appear in Tracy's Enable/Disable window, even if they
haven't been run yet. Using this macro is optional, but it's recommended to call it
from within your module's `__init__` method.
"""
macro register_tracepoints()
    srclocs = meta(__module__)
    return quote
        push!($modules, $__module__)
        foreach($Tracy.initialize!, $srclocs)
    end
end
