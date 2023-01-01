using Test
using Statistics: mean, median, std, var
using StatsBase: mad
using IntervalSets
using DirectionalStatistics
using StaticArrays
using Random

@testset "most distant points" begin
    x = [2, 39, 17, 7, -90, 45, 105, -30, 26, -4]
    @test Set(most_distant_points(x)) == Set([-90, 105])
    @test Set(most_distant_points_ix(x)) == Set([5, 7])

    x = [82, 10, 82, -111, -13, -63, 83, 5, 10, 3] .+ im .* [2, 39, 17, 7, -90, 45, 105, -30, 26, -4]
    @test Set(most_distant_points(x)) == Set([83 + 105im, -13 - 90im])
    @test Set(most_distant_points_ix(x)) == Set([5, 7])

    x = SVector.(real(x), imag(x))
    @test Set(most_distant_points(x)) == Set([[83, 105], [-13, -90]])
    @test Set(most_distant_points_ix(x)) == Set([5, 7])
end

@testset "vec_std" begin
    a = rand(10)
    @test vec_std(a) ≈ std(a)
    @test vec_std([[x] for x in a]) ≈ std(a)
    a = rand(10) + im * rand(10)
    @test vec_std(SVector.(real(a), imag(a))) ≈ std(a)
end

@testset "geometric median" begin
    @testset for func in [
            geometric_median,
            A -> geometric_median(GeometricMedianAlgo.Weiszfeld(), A),
            A -> geometric_median(GeometricMedianAlgo.VardiZhang(), A),
        ]
        @test func([1, 2, 3]) ≈ 2
        @test func([1. + 3im]) ≈ 1 + 3im rtol=1e-5
        @testset for ang in [0, pi, pi/2, 0.1234]
            # collinear - needs to have odd number of elements for uniqueness
            vals = [-3, 0, 0, 1, 2, 5, 10]
            @test func(vals .* exp(im * ang)) ≈ median(vals) * exp(im * ang) rtol=1e-5
            # or equal middle values
            vals = [-3, 0, 1, 2, 2, 5, 10]
            @test func(vals .* exp(im * ang)) ≈ median(vals) * exp(im * ang) rtol=1e-5
        end
        @test func([0, 1, 1im, 1+1im]) ≈ 0.5+0.5im rtol=1e-5
        @test func([0, 1, 1+1im, 0.9+0.8im]) ≈ 0.9+0.8im rtol=1e-5
        @test func([SVector(0, 0), SVector(1, 0), SVector(0, 1), SVector(1, 1)]) == SVector(0.5, 0.5)
    end
end

@testset "geometric mad" begin
    n = 1000
    vals = randn(n) .+ im .* randn(n)
    @test 1.1 < geometric_mad(vals) < 1.3
    @test geometric_mad([vals; 1e50]) ≈ geometric_mad(vals)  rtol=1e-2

    vals_r = rand(5)  # has to be odd for unique median
    @test geometric_mad(vals_r .+ 0im) ≈ mad(vals_r, normalize=false)
    @test geometric_mad(vals_r .* im) ≈ mad(vals_r, normalize=false)
    @test geometric_mad(vals_r .* exp(im * π/4)) ≈ mad(vals_r, normalize=false)
    @test geometric_mad(vals_r .* exp(im * rand())) ≈ mad(vals_r, normalize=false)

    @testset for i in 1:10
        vals = rand(5) .+ im .* rand(5)
        @test geometric_mad(vals .* exp(im * 10 * rand())) ≈ geometric_mad(vals)  rtol=0.3
    end
end

@testset "angle range shift" begin
    for x in [0.01, 1, pi - 0.01, -2]
        @test CircularStats.center_angle(x) ≈ x
        @test CircularStats.center_angle(x + 2pi) ≈ x
        @test CircularStats.center_angle(x - 2pi) ≈ x
        @test CircularStats.to_range(x, -pi..pi) ≈ x
        @test CircularStats.to_range(x + 2pi, -pi..pi) ≈ x
        @test CircularStats.to_range(x - 2pi, -pi..pi) ≈ x
    end

    @test CircularStats.distance(0.5, 1.3) ≈ 0.8
    @test CircularStats.distance(0.5, 4π + 1.3) ≈ 0.8
    @test CircularStats.distance(0.5, 4π + 1.3, range=2π) ≈ 0.8
    @test CircularStats.distance(0.5, 0.25, range=0.1) ≈ 0.05
end

@testset "angular mean" begin
    @test CircularStats.mean(zeros(10)) ≈ 0
    @test CircularStats.mean(ones(10)) ≈ 1
    @test CircularStats.mean(.-ones(10)) ≈ -1
    @test CircularStats.mean(fill(5, 10)) ≈ 5 - 2pi
    
    @test CircularStats.mean(zeros(10), 0..0.3) ≈ 0
    @test CircularStats.mean(ones(10), 0..0.3) ≈ 0.1
    @test CircularStats.mean(.-ones(10), 0..0.3) ≈ -1 + 0.3*4
    @test CircularStats.mean(fill(5, 10), 0..0.3) ≈ 5 % 0.3
    
    vals = [1.80044838, 2.02938314, 1.03534016, 4.84225057, 1.54256458, 5.19290675, 2.18474784, 4.77054777, 1.51736933, 0.72727580]
    avg = 1.35173983
    @test CircularStats.mean(vals) ≈ avg
    @test CircularStats.mean(vals ./ 2pi, 0..1) ≈ avg / 2pi
    @test CircularStats.mean(vals ./ 2pi * 1.5, -1.5..0) ≈ -1.5 + avg / 2pi * 1.5

    vals = 1e-5 .* rand(5)
    @test CircularStats.mean(vals) ≈ mean(vals)
    @test CircularStats.mean(1.2345 .+ vals) ≈ 1.2345 + mean(vals)
    
    # from scipy
    @test Circular.mean([355, 5, 2, 359, 10, 350], 0..360) ≈ 0.167690146
    @test Circular.mean([20, 21, 22, 18, 19, 20.5, 19.2], 0..360) ≈ mean([20, 21, 22, 18, 19, 20.5, 19.2])  rtol=1e-5
    @test Circular.mean([20, 21, 22, 18, 19, 20.5, NaN], 0..360) |> isnan
    
    @testset for (f, fc) in [(mean, Circular.mean), (std, Circular.std), (var, Circular.var)]
        x = [repeat([0.12675364631578953], 10); repeat([0.12675365920187928], 100)]
        @test f(x) ≈ fc(x)  atol=1e-8
    end
end

@testset "angular median" begin
    @test CircularStats.median([0]) == 0
    @test CircularStats.median([0, 0, 0]) == 0
    @test CircularStats.median([-9π/16, -9π/16, 0, 9π/16, 9π/16]) == 0
    @test CircularStats.median([-3π/8, 0, 2π/3]) == 0
    @test CircularStats.median([ 1.39079274, 0.17122657, -0.61367729, -2.56454636, 2.70582513]) == 1.39079274
    @test CircularStats.median([0, 1, 1, 2, 2, 3]) ∈ [1, 2]
    x = [1, 1.2, 2, 2.2, 1+π, 1.2+π, 2+π, 2.2+π]
    @test CircularStats.median(x) ∈ x
end

@testset "angular spread" begin
    @test CircularStats.std(zeros(10)) ≈ 0
    @test CircularStats.std(fill(123, 10)) ≈ 0
    @test CircularStats.var(zeros(10)) ≈ 0
    @test CircularStats.var(fill(123, 10)) ≈ 0
    @test CircularStats.resultant_mean_length(zeros(10)) ≈ 1
    @test CircularStats.resultant_mean_length(fill(123, 10)) ≈ 1
    
    vals = [1.80044838, 2.02938314, 1.03534016, 4.84225057, 1.54256458, 5.19290675, 2.18474784, 4.77054777, 1.51736933, 0.72727580]
    vals_std = 1.46571716843
    vals_var = 0.65841659857
    @test CircularStats.std(vals) ≈ vals_std
    @test CircularStats.std(vals ./ 2pi, 0..1) ≈ vals_std / 2pi
    @test CircularStats.std(vals ./ 2pi * 1.5, -1.5..0) ≈ vals_std / 2pi * 1.5
    @test CircularStats.var(vals) ≈ vals_var

    vals = 1e-3 .* rand(5)
    @test 0.7*std(vals) < CircularStats.std(vals) < std(vals)
    @test 0.7*std(vals) < CircularStats.std(1.2345 .+ vals) < std(vals)
    @test 0.7*var(vals)/2 < CircularStats.var(vals) < var(vals)/2
    @test 0.7*var(vals)/2 < CircularStats.var(1.2345 .+ vals) < var(vals)/2
    @test CircularStats.std(2.5 .* vals) ≈ 2.5 * CircularStats.std(vals)  rtol=1e-3
    @test CircularStats.var(2.5 .* vals) ≈ 2.5^2 * CircularStats.var(vals)  rtol=1e-3
    
    # from scipy
    @test Circular.std([355, 5, 2, 359, 10, 350], 0..360) ≈  6.520702116
    @test_broken Circular.var([355, 5, 2, 359, 10, 350], 0..360) ≈ 42.51955609
    @test_broken Circular.std([20, 21, 22, 18, 19, 20.5, 19.2], 0..360) ≈ std([20, 21, 22, 18, 19, 20.5, 19.2])  rtol=1e-4
    @test_broken Circular.var([20, 21, 22, 18, 19, 20.5, 19.2], 0..360) ≈ var([20, 21, 22, 18, 19, 20.5, 19.2])  rtol=1e-4
    @test Circular.std([20, 21, 22, 18, 19, 20.5, NaN], 0..360) |> isnan
    @test Circular.var([20, 21, 22, 18, 19, 20.5, NaN]) |> isnan
end

@testset "wrap_curve" begin
    @test Circular.wrap_curve_closed(identity, [-20., 0, 100]; rng=-180..180) == [-20, 0, 100]
    @test Circular.wrap_curve_closed(identity, [-20., 0, 100, 200]; rng=-180..180) ≈ [-180, -160, -20, 0, 100, 180]
    @test Circular.wrap_curve_closed(identity, [-200, -20., 0, 100]; rng=-180..180) ≈ [-180, -20, 0, 100, 160, 180]
    @test Circular.wrap_curve_closed(identity, [500., 510, 600]; rng=-180..180) ≈ [-180, -120, 140, 150, 180]
end

@testset "errors" begin
    # MethodError on julia 1.8+, ArgumentError on earlier versions
    # https://github.com/JuliaLang/julia/pull/41885
    exc_type = Union{ArgumentError, MethodError}
    @test_throws exc_type CircularStats.mean([])
    @test_throws exc_type CircularStats.std([])
    @test_throws exc_type CircularStats.var([])
    @test_throws exc_type CircularStats.median([])
end


import Aqua
import CompatHelperLocal as CHL
@testset begin
    CHL.@check()
    Aqua.test_ambiguities(DirectionalStatistics, recursive=false)
    Aqua.test_unbound_args(DirectionalStatistics)
    Aqua.test_undefined_exports(DirectionalStatistics)
    Aqua.test_stale_deps(DirectionalStatistics)
end


using Documenter, DocumenterMarkdown
DocMeta.setdocmeta!(DirectionalStatistics, :DocTestSetup, :(using DirectionalStatistics; using IntervalSets); recursive=true)
makedocs(format=Markdown(), modules=[DirectionalStatistics], root="../docs")
mv("../docs/build/README.md", "../README.md", force=true)
rm("../docs/build", recursive=true)
