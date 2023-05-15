function extract_kwargs(ex0)
    kws = Dict{Symbol, Any}()
    arg = ex0[end] # Mandatory argument
    for i in 1:length(ex0)-1
        x = ex0[i]
        if x isa Expr && x.head === :(=) # Keyword given of the form "foo=bar"
            if length(x.args) != 2
                error("Invalid keyword argument: $x")
            end
            kws[x.args[1]] = esc(x.args[2])
        else
            error("expect only one non-keyword argument")
        end
    end
    return arg, kws
end
