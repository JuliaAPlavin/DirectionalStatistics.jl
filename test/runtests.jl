using TestItems
using TestItemRunner
@run_package_tests

# using Statistics: mean, median, std, var
# using StatsBase: mad
# using IntervalSets
# using DirectionalStatistics
# using StaticArrays
# using Random
# using InverseFunctions
# using Accessors


@testitem "Base.isnan" begin
    isnan(mod2pi(NaN))
end

@testitem "most distant points" begin
    using StaticArrays

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

@testitem "vec_std" begin
    using StaticArrays
    using Statistics

    a = rand(10)
    @test vec_std(a) ≈ std(a)
    @test vec_std([[x] for x in a]) ≈ std(a)
    a = rand(10) + im * rand(10)
    @test vec_std(SVector.(real(a), imag(a))) ≈ std(a)
end

@testitem "geometric median" begin
    using StaticArrays
    using Statistics

    @testset for geomed in [
            geometric_median,
            A -> geometric_median(GeometricMedianAlgo.Weiszfeld(), A),
            A -> geometric_median(GeometricMedianAlgo.VardiZhang(), A),
        ]
        @test geomed([1, 2, 3]) ≈ 2
        @test geomed([1. + 3im]) ≈ 1 + 3im rtol=1e-5
        @testset for ang in [0, pi, pi/2, 0.1234]
            # collinear - needs to have odd number of elements for uniqueness
            vals = [-3, 0, 0, 1, 2, 5, 10]
            @test geomed(vals .* exp(im * ang)) ≈ median(vals) * exp(im * ang) rtol=1e-5
            # or equal middle values
            vals = [-3, 0, 1, 2, 2, 5, 10]
            @test geomed(vals .* exp(im * ang)) ≈ median(vals) * exp(im * ang) rtol=1e-5
        end
        @test geomed([0, 1, 1im, 1+1im]) ≈ 0.5+0.5im rtol=1e-5
        @test geomed([0, 1, 1+1im, 0.9+0.8im]) ≈ 0.9+0.8im rtol=1e-5
        @test geomed([SVector(0, 0), SVector(1, 0), SVector(0, 1), SVector(1, 1)]) == SVector(0.5, 0.5)
    end
end

@testitem "geometric mad" begin
    using StaticArrays
    using StatsBase

    n = 1000
    vals = randn(n) .+ im .* randn(n)
    @test 1.1 < geometric_mad(vals) < 1.3
    @test geometric_mad(vals) ≈ complex(geometric_mad(SVector.(real.(vals), imag.(vals)))...)
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

@testitem "linear range shift" begin
    using IntervalSets
    using InverseFunctions

    f = Base.Fix2(shift_range, 1..2 => 20..30)
    @test f(1) == 20
    @test f(1.6) == 26
    @test f(-2) == -10
    InverseFunctions.test_inverse(f, 1.2)
end

@testitem "angle range shift" begin
    using IntervalSets

    for x in [0.01, 1, pi - 0.01, -2]
        @test Circular.center_angle(x) ≈ x
        @test Circular.center_angle(x + 2pi) ≈ x
        @test Circular.center_angle(x - 2pi) ≈ x

        # to_range is effectively deprecated
        @test Circular.to_range(x, -pi..pi) ≈ x
        @test Circular.to_range(x + 2pi, -pi..pi) ≈ x
        @test Circular.to_range(x - 2pi, -pi..pi) ≈ x
    end

    @test Circular.distance(0.5, 1.3) ≈ 0.8
    @test Circular.distance(0.5, 4π + 1.3) ≈ 0.8
    @test Circular.distance(0.5, 4π + 1.3, period=2π) ≈ 0.8
    @test Circular.distance(0.5, 0.25, period=0.1) ≈ 0.05
end

@testitem "angular mean" begin
    using Statistics
    using IntervalSets

    @test Circular.mean(zeros(10)) ≈ 0
    @test Circular.mean(ones(10)) ≈ 1
    @test Circular.mean(.-ones(10)) ≈ -1
    @test Circular.mean(fill(5, 10)) ≈ 5 - 2pi
    
    @test Circular.mean(zeros(10), 0..0.3) ≈ 0
    @test Circular.mean(ones(10), 0..0.3) ≈ 0.1
    @test Circular.mean(.-ones(10), 0..0.3) ≈ -1 + 0.3*4
    @test Circular.mean(fill(5, 10), 0..0.3) ≈ 5 % 0.3
    
    vals = [1.80044838, 2.02938314, 1.03534016, 4.84225057, 1.54256458, 5.19290675, 2.18474784, 4.77054777, 1.51736933, 0.72727580]
    avg = 1.35173983
    @test Circular.mean(vals) ≈ avg
    @test Circular.mean(vals ./ 2pi, 0..1) ≈ avg / 2pi
    @test Circular.mean(vals ./ 2pi * 1.5, -1.5..0) ≈ -1.5 + avg / 2pi * 1.5

    vals = 1e-5 .* rand(5)
    @test Circular.mean(vals) ≈ mean(vals)
    @test Circular.mean(1.2345 .+ vals) ≈ 1.2345 + mean(vals)

    @test Circular.mean([0:0.2:π;0.4π:0.05:0.6π;π:0.4:2π]) ≈ 1.568889360630885
    
    # from scipy
    @test Circular.mean([355, 5, 2, 359, 10, 350], 0..360) ≈ 0.167690146
    @test Circular.mean([20, 21, 22, 18, 19, 20.5, 19.2], 0..360) ≈ mean([20, 21, 22, 18, 19, 20.5, 19.2])  rtol=1e-5
    @test Circular.mean([20, 21, 22, 18, 19, 20.5, NaN], 0..360) |> isnan

    @test Circular.mean([43, 45, 52, 61, 75, 88, 88, 279, 357], 0..360) ≈ 51 atol=0.1  # Example 1.1 of Mardia & Jupp (2000)
    
    @testset for (f, fc) in [(mean, Circular.mean), (std, Circular.std), (var, Circular.var)]
        x = [repeat([0.12675364631578953], 10); repeat([0.12675365920187928], 100)]
        @test f(x) ≈ fc(x)  atol=1e-8
    end
end

@testitem "angular median" begin
    using IntervalSets

    @test Circular.median([0]) == 0
    @test Circular.median([0, 0, 0]) == 0
    @test Circular.median([-9π/16, -9π/16, 0, 9π/16, 9π/16]) == 0
    @test Circular.median([-3π/8, 0, 2π/3]) == 0
    @test Circular.median([ 1.39079274, 0.17122657, -0.61367729, -2.56454636, 2.70582513]) == 1.39079274
    @test Circular.median([0, 1, 1, 2, 2, 3]) ∈ [1, 2]
    x = [1, 1.2, 2, 2.2, 1+π, 1.2+π, 2+π, 2.2+π]
    @test Circular.median(x) ∈ x
    @test Circular.median([0:0.2:π;0.4π:0.05:0.6π;π:0.4:2π]) ≈ 1.556637061435917
    @test Circular.median([43, 45, 52, 61, 75, 88, 88, 279, 357], 0..360) ≈ 52  # Example 1.1 of Mardia & Jupp (2000)
end

@testitem "angular spread" begin
    using Statistics
    using IntervalSets

    @test Circular.std(zeros(10)) ≈ 0
    @test Circular.std(fill(123, 10)) ≈ 0
    @test Circular.var(zeros(10)) ≈ 0
    @test Circular.var(fill(123, 10)) ≈ 0
    @test Circular.resultant_mean_length(zeros(10)) ≈ 1
    @test Circular.resultant_mean_length(fill(123, 10)) ≈ 1
    
    vals = [1.80044838, 2.02938314, 1.03534016, 4.84225057, 1.54256458, 5.19290675, 2.18474784, 4.77054777, 1.51736933, 0.72727580]
    vals_std = 1.46571716843
    vals_var = 0.65841659857
    @test Circular.std(vals) ≈ vals_std
    @test Circular.std(vals ./ 2pi, 0..1) ≈ vals_std / 2pi
    @test Circular.std(vals ./ 2pi * 1.5, -1.5..0) ≈ vals_std / 2pi * 1.5
    @test Circular.var(vals) ≈ vals_var

    vals = 1e-3 .* rand(5)
    @test 0.7*std(vals) < Circular.std(vals) < std(vals)
    @test 0.7*std(vals) < Circular.std(1.2345 .+ vals) < std(vals)
    @test 0.7*var(vals)/2 < Circular.var(vals) < var(vals)/2
    @test 0.7*var(vals)/2 < Circular.var(1.2345 .+ vals) < var(vals)/2
    @test Circular.std(2.5 .* vals) ≈ 2.5 * Circular.std(vals)  rtol=1e-3
    @test Circular.var(2.5 .* vals) ≈ 2.5^2 * Circular.var(vals)  rtol=1e-3
    @test Circular.std([0:0.2:π;0.4π:0.05:0.6π;π:0.4:2π]) ≈ 1.209651009981690
    @test Circular.var([0:0.2:π;0.4π:0.05:0.6π;π:0.4:2π]) ≈ 0.518874815053895
    
    # from scipy
    @test Circular.std([355, 5, 2, 359, 10, 350], 0..360) ≈  6.520702116
    @test_broken Circular.var([355, 5, 2, 359, 10, 350], 0..360) ≈ 42.51955609
    @test_broken Circular.std([20, 21, 22, 18, 19, 20.5, 19.2], 0..360) ≈ std([20, 21, 22, 18, 19, 20.5, 19.2])  rtol=1e-4
    @test_broken Circular.var([20, 21, 22, 18, 19, 20.5, 19.2], 0..360) ≈ var([20, 21, 22, 18, 19, 20.5, 19.2])  rtol=1e-4
    @test Circular.std([20, 21, 22, 18, 19, 20.5, NaN], 0..360) |> isnan
    @test Circular.var([20, 21, 22, 18, 19, 20.5, NaN]) |> isnan

    @test Circular.var([43, 45, 52, 61, 75, 88, 88, 279, 357] .|> deg2rad) ≈ 1 - 0.711 atol=0.001  # Example 1.1 of Mardia & Jupp (2000)
end


@testitem "sample range" begin
    using IntervalSets
    import Random

    Base.isapprox(a::Interval, b::Interval; kwds...) = isapprox(collect(endpoints(a)), collect(endpoints(b)); kwds...)

    @test Circular.sample_range([-1, 0, 2]) ≈ 3
    @test Circular.sample_range([-1, 0, 1, 2, 3, 4]) ≈ 5.0
    @test Circular.sample_range([-1, 0, 2, 3, 4]) ≈ 4.283185307179586
    @test Circular.sample_range([-1, 0, 2, 5, 6]) ≈ 3.2831853071795862
    @test Circular.sample_range([-1, 4π]) ≈ 1.0
    @test Circular.sample_range([0, 1], 0..π) ≈ 1.0

    @test Circular.sample_interval([-1, 0, 2]) ≈ -1.0..2.0
    @test Circular.sample_interval([-1, 0, 1, 2, 3, 4]) ≈ -1.0..(-2.2831853071795862)
    @test Circular.sample_interval([-1, 0, 2, 3, 4]) ≈ 2.0..0.0
    @test Circular.sample_interval([-1, 0, 2, 5, 6]) ≈ -1.2831853071795862..2.0
    @test Circular.sample_interval([-1, 4π]) ≈ -1.0..0.0
    @test Circular.sample_interval([0, 1], 0..π) ≈ 0..1

    Random.seed!(123)
    for _ in 1:100
        x = rand(5)
        @test Circular.sample_range(x) ≈ width(Circular.sample_interval(x))
        @test Circular.sample_range(x, 1..5) ≈ width(Circular.sample_interval(x, 1..5))
    end
end

@testitem "unwrap" begin
    using IntervalSets

    @test Circular.unwrap([0.1, 0.2, 0.3, 0.4]) ≈ [0.1, 0.2, 0.3, 0.4]
    @test Circular.unwrap([0.1, 0.2 + 2π, 0.3, 0.4]) ≈ [0.1, 0.2, 0.3, 0.4]
    @test Circular.unwrap([0.1, 0.2 - 2π, 0.3, 0.4]) ≈ [0.1, 0.2, 0.3, 0.4]
    @test Circular.unwrap([0.1, 0.2 - 2π, 0.3 - 2π, 0.4]) ≈ [0.1, 0.2, 0.3, 0.4]
    @test Circular.unwrap([0.1 + 2π, 0.2, 0.3, 0.4]) ≈ [0.1 + 2π, 0.2 + 2π, 0.3 + 2π, 0.4 + 2π]
    @test Circular.unwrap([0.1, 0.2 + 6pi, 0.3, 0.4]) ≈ [0.1, 0.2, 0.3, 0.4]
    
    @test Circular.unwrap([0.1, 0.2 + 2π, 0.3, 0.4]; refix=2) ≈ [0.1, 0.2, 0.3, 0.4] .+ 2π

    unwrapped = 1:100
    wrapped = unwrapped .% 10
    @test Circular.unwrap(wrapped; period=10)::Vector{Int} == unwrapped

    test_v = [0.1, 0.2, 0.3 + 2π, 0.4]
    @test Circular.unwrap(test_v) ≈ [0.1, 0.2, 0.3, 0.4]
    @test test_v == [0.1, 0.2, 0.3 + 2π, 0.4]
    @test Circular.unwrap!(test_v) === test_v ≈ [0.1, 0.2, 0.3, 0.4]

    for _ in 1:10
        unwrapped = cumsum(rand(-1..1, 10))
        period = 2 + rand()
        wrapped = unwrapped .% period
        @test Circular.unwrap(wrapped; period) ≈ unwrapped
        @test Circular.unwrap(wrapped; refix=5, period) ≈ unwrapped .+ (wrapped[5] - unwrapped[5])
    end
end

@testitem "wrap_curve" begin
    using IntervalSets
    using Accessors
    using SkyCoords
    using SkyCoords: lat, lon
    using StaticArrays

    Base.isapprox(a::Vector{<:ICRSCoords}, b::Vector{<:ICRSCoords}; kwargs...) = all(map((a, b) -> isapprox(a, b; kwargs...), a, b))
    function ≈ₐ(a, b; kwargs...)
        res = all(map((a, b) -> isapprox(a, Circular.center_angle(b; at=a, period=360); kwargs...), a, b))
        res || @show a b
        res
    end

    @testset for (orig, rng, expected) in [
        ([-20., 0, 100, 200], -180..180, [-180, -160, -20, 0, 100, 180]),
        ([-200, -60., 0, 100], -180..180, [-180, -60, 0, 100, 160, 180]),
        (360*10 .+ [-200, -60., 0, 100], -180..180, [-180, -60, 0, 100, 160, 180]),
        ([100., 150, 200, 340, 370], -180..180, [-180, -160, -20, 10, 100, 150, 180]),
        ([-20., 0, 100], -180..180, [-20, 0, 100]),
        ([10., 100, 150, -160, -20], -180..180, [-180, -160, -20, 10, 100, 150, 180]),
        ([100., 150, 200, 300, 350, 20, 50], -180..180, [-180, -160, -60, -10, 20, 50, 100, 150, 180]),
        ([120., 150, 170, -170, -120, -160, 175], -180..180, [-180, -170, -120, -160, -180, NaN, 180, 175, 120, 150, 170, 180]),
    ]
        @test Circular.wrap_curve_closed(orig; rng) ≈ expected  nans=true atol=1e-5
        @test Circular.wrap_curve_closed(orig .- leftendpoint(rng); rng=0..width(rng)) ≈ expected .- leftendpoint(rng)  nans=true atol=1e-5
        opt = @optic(_.a)
        @test opt.(Circular.wrap_curve_closed(opt, [(;a) for a in orig]; rng)) ≈ expected  nans=true atol=1e-5
        @test opt.(Circular.wrap_curve_closed(opt, [(;a) for a in orig .- leftendpoint(rng)]; rng=0..width(rng))) ≈ expected .- leftendpoint(rng)  nans=true atol=1e-5
        opt = @optic(rad2deg(_.ra))
        @test opt.(Circular.wrap_curve_closed(opt, ICRSCoords.(deg2rad.(orig), 1); rng)) ≈ₐ
            opt.(ICRSCoords.(deg2rad.(expected), 1))  nans=true atol=1e-5
        @test opt.(Circular.wrap_curve_closed(opt, ICRSCoords.(deg2rad.(orig .- leftendpoint(rng)), 1); rng=0..width(rng))) ≈ₐ
            opt.(ICRSCoords.(deg2rad.(expected .- leftendpoint(rng)), 1))  nans=true atol=1e-5
    end

    orig = [
        ICRSCoords(1.50805, 0.505031),
        ICRSCoords(1.85171, -0.109732),
        ICRSCoords(2.25097, -0.709714),
        ICRSCoords(3.25418, -1.09477),
        ICRSCoords(4.39375, -0.789696),
        ICRSCoords(4.83251, -0.200514),
        ICRSCoords(5.16576, 0.416966),
        ICRSCoords(5.75965, 0.960801),
        ICRSCoords(0.817046, 1.01749),
        ICRSCoords(1.50805, 0.505031),
    ]
    actual = Circular.wrap_curve_closed(@optic(rad2deg(_.ra)), orig; rng=0..360)
    @test actual ≈ [
        ICRSCoords(0, 1.01749),
        ICRSCoords(0.817046, 1.01749),
        ICRSCoords(1.50805, 0.505031),
        ICRSCoords(1.50805, 0.505031),
        ICRSCoords(1.85171, -0.109732),
        ICRSCoords(2.25097, -0.709714),
        ICRSCoords(3.25418, -1.09477),
        ICRSCoords(4.39375, -0.789696),
        ICRSCoords(4.83251, -0.200514),
        ICRSCoords(5.16576, 0.416966),
        ICRSCoords(5.75965, 0.960801),
        ICRSCoords(2π - eps(1.), 0.960801),
    ]  rtol=1e-5

    orig = [
        ICRSCoords(1.5080515357473396, 0.505031),
        ICRSCoords(1.85171, -0.109732),
        ICRSCoords(2.25097, -0.709714),
        ICRSCoords(3.25418, -1.09477),
        ICRSCoords(4.39375, -0.789696),
        ICRSCoords(4.83251, -0.200514),
        ICRSCoords(5.16576, 0.416966),
        ICRSCoords(5.75965, 0.960801),
        ICRSCoords(0.817046, 1.01749),
        ICRSCoords(1.5080515357473394, 0.505031),
    ]
    actual = Circular.wrap_curve_closed(@optic(_.ra), orig; rng=0..2π)
    @test actual ≈ [
        ICRSCoords(0, 1.01749),
        ICRSCoords(0.817046, 1.01749),
        ICRSCoords(1.5080515357473394, 0.505031),
        ICRSCoords(1.5080515357473396, 0.505031),
        ICRSCoords(1.85171, -0.109732),
        ICRSCoords(2.25097, -0.709714),
        ICRSCoords(3.25418, -1.09477),
        ICRSCoords(4.39375, -0.789696),
        ICRSCoords(4.83251, -0.200514),
        ICRSCoords(5.16576, 0.416966),
        ICRSCoords(5.75965, 0.960801),
        ICRSCoords(2π - eps(1.), 0.960801),
    ]  rtol=1e-5
end

@testitem "errors" begin
    # MethodError on julia 1.8+, ArgumentError on earlier versions
    # https://github.com/JuliaLang/julia/pull/41885
    exc_type = Union{ArgumentError, MethodError}
    @test_throws exc_type Circular.mean([])
    @test_throws exc_type Circular.std([])
    @test_throws exc_type Circular.var([])
    @test_throws exc_type Circular.median([])
end

@testitem "_" begin
    import Aqua
    Aqua.test_all(DirectionalStatistics; ambiguities=false)
    Aqua.test_ambiguities(DirectionalStatistics)

    import CompatHelperLocal as CHL
    CHL.@check()
end
