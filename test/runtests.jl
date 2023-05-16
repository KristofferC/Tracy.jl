module BasicTests
    using Tracy
    using Test
    using Pkg

    @tracepoint "test tracepoint" begin
	    println("Hello, world!")
    end

    @test_throws ErrorException @tracepoint "test exception" begin
        error("oh no!")
    end

    # Various ways to trace a function
    @tracepoint "zone f" f(x) = x^2
    foreach(n -> f(n), 1:10)
    @tracepoint function g(x)
        x^2
    end
    foreach(n -> g(n), 1:20)
    @tracepoint "hxT" function h(x::T) where {T}
        T(x^2)
    end
    foreach(n -> h(n), 1:30)
    i = @tracepoint x->x^2
    foreach(n -> i(n), 1:40)

    Pkg.activate("TestPkg")
    Pkg.develop(; path = joinpath(@__DIR__, ".."))
    # Test that a precompiled package also works,
    # Can also be manually verified by attaching Tracy to this process
    # withenv("JULIA_WAIT_FOR_TRACY"=>"1", "TRACY_PORT"=>"9000") do
        run(`$(Base.julia_cmd()) --project="TestPkg" -e 'using TestPkg; TestPkg.time_something(); TestPkg.test_data()'`)
    # end
end
