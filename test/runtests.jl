module BasicTests
    using Tracy
    using Test

    @tracepoint "test tracepoint" begin
	    println("Hello, world!")
    end

    @test_throws ErrorException @tracepoint "test exception" begin
        error("oh no!")
    end

    tracymsg("Hello, world!")
    tracymsg(SubString("Hello, world!"), 0xFF00FF)

    for i in range(0, 2π, length=1000)
        sleep(1 / length() * rand())
        @tracyplot("myplot", sin(i))
    end
end
