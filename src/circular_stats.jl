module Circular

using IntervalSets
import StatsBase
using Accessors
using InverseFunctions
import ..shift_range


""" Center angular value `x` to be within a symmetric range of length `period` around `at`, from `at - period/2` to `at + period/2`. Assumes circular structure: `x + period` is equivalent to `x`.

```jldoctest
julia> Circular.center_angle(0)
0.0

julia> Circular.center_angle(4π + 1)
1.0

julia> Circular.center_angle(4π - 1)
-1.0

julia> Circular.center_angle(10, at=0, period=3)
1.0
```
"""
center_angle(x; at=0, period=2π, range=period) = mod(x, at ± range/2)

""" Transform `x` to be within the range `rng` assuming circular structure: `x + width(rng)` is equivalent to `x`. In effect, this adds the necessary multiple of `width(rng)` to `x` so that it falls into `rng`.

This is deprecated, and means the same as `mod(x, rng)`.

```jldoctest
julia> Circular.to_range(0, 0..2π)
0.0

julia> Circular.to_range(4π + 1, 0..2π)
1.0

julia> Circular.to_range(5.5, -1..1)
-0.5
```
"""
to_range(x, rng::Interval) = mod(x, rng)

""" Distance between two angles, `x` and `y`. Assumes circular structure: `x + period` is equivalent to `x`.

```jldoctest
julia> Circular.distance(0, 1)
1.0

julia> Circular.distance(0, 4π + 1)
1.0

julia> Circular.distance(0, 5.5, period=3)
0.5
```
"""
distance(x, y; period=2π, range=period) = abs(center_angle(x - y; range))


resultant_vector(x) = sum(cis, x)
resultant_mean_vector(x) = resultant_vector(x) / length(x)
resultant_length(x) = abs(resultant_vector(x))
resultant_mean_length(x) = abs(resultant_mean_vector(x))

""" Mean of a collection of circular data.

```jldoctest
julia> Circular.mean([0, 1, 2, 3])
1.5

julia> Circular.mean([1, 2π]) ≈ 0.5
true

julia> Circular.mean([1, 5], 0..4) ≈ 1
true
```
"""
mean(x) = angle(resultant_vector(x))
function mean(x, rng::Interval)
    sr = @optic shift_range(_, rng => -π..π)
    inverse(sr)(mean(Iterators.map(sr, x)))
end

""" Variance of a collection of circular data. """
var(x) = 1 - resultant_mean_length(x)

""" Standard deviation of a collection of circular data.

```jldoctest
julia> Circular.std([0])
0.0

julia> Circular.std([0, 1, 2, 3])
1.2216470118898806

julia> Circular.std([0, 2π])
0.0

julia> Circular.std([0, 1, 2, 3], -10..10)
1.126024231452878
```
"""
std(x) = √(max(0, -2 * log(resultant_mean_length(x))))
std(x, rng::Interval) = std(Iterators.map(x -> shift_range(x, rng => -π..π), x)) * width(rng) / 2π


""" Median of a collection of circular data.

Computes the median that minimizes the sum of arc distances sense. Always returns one of the datapoints, so the result is a medoid.

For discussion of different circular medians see e.g. https://hci.iwr.uni-heidelberg.de/sites/default/files/profiles/mstorath/files/storath2017fast.pdf.

```jldoctest
julia> Circular.median([0, 1, 2])
1

julia> Circular.median([0.05, 2π - 0.1, 6π + 0.1])
0.05

julia> Circular.median([0, 1, 2], -2..4)
1.0
```
"""
median(x) = argmin(a -> sum(b -> distance(a, b), x), x)
function median(x, rng::Interval)
    sr = @optic shift_range(_, rng => -π..π)
    inverse(sr)(median(Iterators.map(sr, x)))
end

""" Sample range - the shortest arc distance encompassing all of the data in the collection.

```jldoctest
julia> Circular.sample_range([-1, 0, 2])
3.0

julia> Circular.sample_range([-1, 0, 1, 2, 3, 4])
5.0

julia> Circular.sample_range([-1, 0, 2, 3, 4])
4.283185307179586

julia> Circular.sample_range([-1, 0, 2, 5, 6])
3.2831853071795862

julia> Circular.sample_range([-1, 4π])
1.0

julia> Circular.sample_range([0, 1], 0..π)
1.0
```
"""
function sample_range(x)
    xs = sort(mod.(x, Ref(-π..π)))
    spacings = [diff(xs); mod2pi(xs[begin] - xs[end])]
    return 2π - maximum(spacings)
end

function sample_interval(x)
    xs = sort(mod.(x, Ref(-π..π)))
    spacings = [diff(xs); mod2pi(xs[begin] - xs[end])]
    i = argmax(spacings)
    return xs[mod(i+1, eachindex(xs))]..xs[mod(i, eachindex(xs))]
end

sample_range(x, rng::Interval) = sample_range(shift_range.(x, rng => -π..π)) * width(rng) / 2π
function sample_interval(x, rng::Interval)
    sr = @optic shift_range(_, rng => -π..π)
    int = sample_interval(map(sr, x))
    # @modify(inverse(sr), endpoints(int) |> Elements()):
    return setproperties(int, map(inverse(sr), Accessors.getproperties(int)))
end


""" Median absolute deviation (MAD) of a collection of circular data.

```jldoctest
julia> Circular.mad([0])
0.0

julia> Circular.mad([0, 1, 2])
1.0

julia> Circular.mad([0, 2π + 1, 2])
1.0

julia> Circular.mad([0, 1, 2], -2..4) ≈ 1
true
```
"""
mad(x) = StatsBase.median(abs.(center_angle.(x .- median(x))))
mad(x, rng::Interval) = mad(shift_range.(x, rng => -π..π)) * width(rng) / 2π


"""    unwrap(A; refix=firstindex(A), period=2π, tol=period/2)

Assumes `A` is a sequence of values that has been wrapped with the given `period`, and undoes the wrapping by identifying discontinuities.
Whenever the jump between consecutive values is greater than or equal to `tol`, shift the later value by adding the proper multiple of `period`.
"""
unwrap(A::AbstractVector; kwargs...) = unwrap!(copy(A); kwargs...)

"""    unwrap!(A; refix=firstindex(A), period=2π, tol=period/2)

Assumes `A` is a sequence of values that has been wrapped with the given `period`, and undoes the wrapping by identifying discontinuities.
Whenever the jump between consecutive values is greater than or equal to `tol`, shift the later value by adding the proper multiple of `period`.
"""
function unwrap!(A::AbstractVector; refix=firstindex(A), period=2π, tol=period/2)
    @assert tol ≥ period / 2
    for ixs in [(refix + 1):lastindex(A), (refix - 1):-1:firstindex(A)]
        for i in ixs
            Δ = A[i] - A[i - step(ixs)]
            Δmod = mod(Δ, 0 ± period/2)
            correction = abs(Δ) > tol ? Δmod - Δ : zero(Δmod)
            # @info "" A[i] A[i-1] Δ Δmod correction
            A[i] += correction
        end
    end
    return A
end


"""    wrap_curve_closed([f=identity], data; rng)

Assuming `data` represents a closed curve with circular structure in `f.(data)`, wrap `data` so that it goes from `minimum(rng) + eps` to `maximum(rng) - eps`.
A common usecase is plotting such curves.

```julia
julia> wrap_curve_closed(identity, [-20., 0, 100, 200]; rng=-180..180)
[-180, -160, -20, 0, 100, 180]  # approximately: endpoints are slightly moved inwards
```
"""
function wrap_curve_closed end

wrap_curve_closed(data; rng) = wrap_curve_closed(identity, data; rng)
function wrap_curve_closed(f, data; rng)
    ε = √eps(1.0)

    # try putting all values into range
    data = @modify(fx -> mod(fx, rng), data |> Elements() |> f)

    # this isn't always possible: e.g. SkyCoords always do mod2pi(ra) on construction
    # but proper range boundaries are needed in is_wrap()
    f_rng = @optic mod(f(_), rng)
    is_wrap(a, b) = distance(f(a), f(b); period=width(rng)) < abs(f_rng(a) - f_rng(b)) * (1 - ε) - ε

    data = @modify(data |> _ConsecutivePairs() |> If(((a, b),) -> is_wrap(a, b))) do p
        [
            p[1],
            modify(fx -> _nearest_endpoint(rng, fx; pad=ε), p[1], f),
            set(p[2], f, NaN),
            modify(fx -> _nearest_endpoint(rng, fx; pad=ε), p[2], f),
            p[2],
        ]
    end
    # move any of the NaNs to the front:
    ix = findfirst(x -> isnan(f(x)), data)
    isnothing(ix) ? data : vcat(data[ix+1:end], data[begin:ix-1])
end

function _nearest_endpoint(int, x; pad)
    x = mod(x, int)
    ep = argmin(ep -> abs(ep - x), endpoints(int))
    ep + sign(x - ep) * pad
end

struct _ConsecutivePairs end
Accessors.OpticStyle(::Type{_ConsecutivePairs}) = Accessors.ModifyBased()

function Accessors.modify(f, obj::AbstractVector, ::_ConsecutivePairs)
    tups = [tuple.(obj[begin:end-1], obj[begin+1:end]); (obj[end], obj[begin])]
    new_tups = map(f, tups)
    @assert all(last.(new_tups[begin:end-1]) .== first.(new_tups[begin+1:end]))
    reduce(vcat, map(t -> collect(t[1:end-1]), new_tups))
end

end
