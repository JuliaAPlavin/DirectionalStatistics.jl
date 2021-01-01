using Test
using Statistics: median, std
using StatsBase: mad
using IntervalSets
using DirectionalStatistics
using StaticArrays

import Aqua
import CompatHelperLocal
@testset begin
    CompatHelperLocal.@check()
    Aqua.test_ambiguities(DirectionalStatistics, recursive=false)
    Aqua.test_unbound_args(DirectionalStatistics)
    Aqua.test_undefined_exports(DirectionalStatistics)
    Aqua.test_stale_deps(DirectionalStatistics)
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
    @test 0.85 < geometric_mad(vals) < 1.05
    vals = [vals; 1e50]
    @test 0.85 < geometric_mad(vals) < 1.05

    vals_r = rand(5)  # has to be odd for unique median
    @test geometric_mad(vals_r .+ 0im) ≈ mad(vals_r, normalize=false)
    @test geometric_mad(vals_r .* im) ≈ mad(vals_r, normalize=false)
    @test geometric_mad(vals_r .* exp(im * π/4)) ≈ mad(vals_r, normalize=false)
    @test geometric_mad(vals_r .* exp(im * rand())) ≈ mad(vals_r, normalize=false)

    vals = rand(5) .+ im .* rand(5)
    @test_broken geometric_mad(vals .* exp(im * rand())) ≈ geometric_mad(vals)
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
end

@testset "angular spread" begin
    @test CircularStats.std(zeros(10)) ≈ 0
    @test CircularStats.std(fill(123, 10)) ≈ 0
    @test CircularStats.var(zeros(10)) ≈ 0
    @test CircularStats.var(fill(123, 10)) ≈ 0
    @test CircularStats.resultant_mean_length(zeros(10)) |> abs ≈ 1
    @test CircularStats.resultant_mean_length(fill(123, 10)) |> abs ≈ 1
    
    vals = [1.80044838, 2.02938314, 1.03534016, 4.84225057, 1.54256458, 5.19290675, 2.18474784, 4.77054777, 1.51736933, 0.72727580]
    std = 1.46571716843
    var = 0.65841659857

    @test CircularStats.std(vals) ≈ std
    @test CircularStats.std(vals ./ 2pi, 0..1) ≈ std / 2pi
    @test CircularStats.std(vals ./ 2pi * 1.5, -1.5..0) ≈ std / 2pi * 1.5

    @test CircularStats.var(vals) ≈ var
end
