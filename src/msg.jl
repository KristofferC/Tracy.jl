# TODO: Named colors
function tracymsg(msg::AbstractString, color::Union{Integer,Nothing}=nothing)
    if color === nothing
        @ccall libtracy.___tracy_emit_message(msg::Cstring, length(msg)::Csize_t)::Cvoid
    else
        @ccall libtracy.___tracy_emit_messageC(msg::Cstring, length(msg)::Csize_t, color::UInt32)::Cvoid
    end
end
