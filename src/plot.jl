macro tracyplot(name::String, value)
    configured = Ref(C_NULL)
    name = QuoteNode(Symbol(name))
    return quote
        if $configured[] === C_NULL
            # @ccall libtracy.___tracy_emit_plot_config($name::Cstring, type::Cint, step::Cint, fill::Cint, color::UInt32)::Cvoid
            $configured[] = Ptr{Cvoid}(1)
        end
        local v = $(esc(value))
        if v isa Integer
            @ccall libtracy.___tracy_emit_plot_int($name::Cstring, v::Cint)::Cvoid
        elseif v isa Float32
            @ccall libtracy.___tracy_emit_plot_float($name::Cstring, v::Cfloat)::Cvoid
        else
            @ccall libtracy.___tracy_emit_plot($name::Cstring, Float64(v)::Cdouble)::Cvoid
        end
    end
end
