module TestUtils

using Test, DataFrames

@testset "make_unique" begin
    @test DataFrames.make_unique([:x, :x, :x_1, :x2], makeunique=true) == [:x, :x_2, :x_1, :x2]
    @test_throws ArgumentError DataFrames.make_unique([:x, :x, :x_1, :x2], makeunique=false)
    @test DataFrames.make_unique([:x, :x_1, :x2], makeunique=false) == [:x, :x_1, :x2]
end

@testset "repeat count" begin
    df = DataFrame(a = 1:2, b = 3:4)
    ref = DataFrame(a = repeat(1:2, 2),
                    b = repeat(3:4, 2))
    @test repeat(df, 2) == ref
    @test repeat(view(df, 1:2, :), 2) == ref

    @test size(repeat(df, 0)) == (0, 2)
    @test size(repeat(df, false)) == (0, 2)
    @test_throws ArgumentError repeat(df, -1)
end

@testset "repeat inner_outer" begin
    df = DataFrame(a = 1:2, b = 3:4)
    ref = DataFrame(a = repeat(1:2, inner = 2, outer = 3),
                    b = repeat(3:4, inner = 2, outer = 3))
    @test repeat(df, inner = 2, outer = 3) == ref
    @test repeat(view(df, 1:2, :), inner = 2, outer = 3) == ref

    @test size(repeat(df, inner = 2, outer = 0)) == (0, 2)
    @test size(repeat(df, inner = 0, outer = 3)) == (0, 2)
    @test size(repeat(df, inner = 2, outer = false)) == (0, 2)
    @test size(repeat(df, inner = false, outer = 3)) == (0, 2)
    @test_throws ArgumentError repeat(df, inner = 2, outer = -1)
    @test_throws ArgumentError repeat(df, inner = -1, outer = 3)
end

@testset "repeat! count" begin
    df = DataFrame(a = 1:2, b = 3:4)
    ref = DataFrame(a = repeat(1:2, 2),
                    b = repeat(3:4, 2))
    a = df.a
    b = df.b
    repeat!(df, 2)
    @test df == ref
    @test a == 1:2
    @test b == 3:4

    for v in (0, false)
        df = DataFrame(a = 1:2, b = 3:4)
        repeat!(df, v)
        @test size(df) == (0, 2)
    end

    df = DataFrame(a = 1:2, b = 3:4)
    @test_throws ArgumentError repeat(df, -1)
    @test df == DataFrame(a = 1:2, b = 3:4)

    @test_throws MethodError repeat!(view(df, 1:2, :), 2)
end

@testset "repeat! inner_outer" begin
    df = DataFrame(a = 1:2, b = 3:4)
    ref = DataFrame(a = repeat(1:2, inner = 2, outer = 3),
                    b = repeat(3:4, inner = 2, outer = 3))
    a = df.a
    b = df.b
    repeat!(df, inner = 2, outer = 3)
    @test df == ref
    @test a == 1:2
    @test b == 3:4

    for v in (0, false)
        df = DataFrame(a = 1:2, b = 3:4)
        repeat!(df, inner = 2, outer = v)
        @test size(df) == (0, 2)

        df = DataFrame(a = 1:2, b = 3:4)
        repeat!(df, inner = v, outer = 3)
        @test size(df) == (0, 2)
    end

    df = DataFrame(a = 1:2, b = 3:4)
    @test_throws ArgumentError repeat(df, inner = 2, outer = -1)
    @test_throws ArgumentError repeat(df, inner = -1, outer = 3)
    @test df == DataFrame(a = 1:2, b = 3:4)

    @test_throws MethodError repeat!(view(df, 1:2, :), inner = 2, outer = 3)
end

@testset "funname" begin
    @test DataFrames.funname(sum ∘ skipmissing ∘ Base.div12) ==
          :sum_skipmissing_div12
end

@testset "pre-Julia 1.3 @spawn replacement" begin
    t = @sync DataFrames.@spawn begin
        sleep(1)
        true
    end
    @test fetch(t) === true
end

@testset "split_indices" begin
    for len in 1:100, basesize in 1:10
        x = DataFrames.split_indices(len, basesize)

        @test length(x) == max(1, div(len, basesize))
        @test reduce(vcat, x) == 1:len
        vmin, vmax = extrema(length(v) for v in x)
        @test vmin + 1 == vmax || vmin == vmax
        @test len < basesize || vmin >= basesize
    end

    @test_throws AssertionError DataFrames.split_indices(0, 10)
    @test_throws AssertionError DataFrames.split_indices(10, 0)

    # Check overflow on 32-bit
    len = typemax(Int32)
    basesize = 100_000_000
    x = collect(DataFrames.split_indices(len, basesize))
    @test length(x) == div(len, basesize)
    @test x[1][1] === 1
    @test x[end][end] === Int(len)
    vmin, vmax = extrema(length(v) for v in x)
    @test vmin + 1 == vmax || vmin == vmax
    @test len < basesize || vmin >= basesize
end

@testset "split_to_chunks" begin
    for lg in 1:100, nt in 1:11
        if lg < nt
            @test_throws AssertionError DataFrames.split_to_chunks(lg, nt)
            continue
        end
        x = collect(DataFrames.split_to_chunks(lg, nt))
        @test reduce(vcat, x) == 1:lg
        @test sum(length, x) == lg
        @test first(x[1]) == 1
        @test last(x[end]) == lg
        @test length(x) == nt
        for i in 1:nt-1
            @test first(x[i+1])-last(x[i]) == 1
        end
    end

    @test_throws AssertionError DataFrames.split_to_chunks(0, 10)
    @test_throws AssertionError DataFrames.split_to_chunks(10, 0)
    @test_throws AssertionError DataFrames.split_to_chunks(10, 11)
end

end # module
