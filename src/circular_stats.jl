module Circular

using IntervalSets
import StatsBase
using Accessors
using InverseFunctions
import ..shift_range


""" Center angular value `x` to be within a symmetric range of length `range` around `at`, from `at - range/2` to `at + range/2`. Assumes circular structure: `x + range` is equivalent to `x`.

```jldoctest
julia> Circular.center_angle(0)
0.0

julia> Circular.center_angle(4π + 1)
1.0

julia> Circular.center_angle(4π - 1)
-1.0

julia> Circular.center_angle(10, at=0, range=3)
1.0
```
"""
center_angle(x; at = 0, range = 2π) = to_range(x, (at - range / 2)..(at + range/2))

""" Transform `x` to be within the range `rng` assuming circular structure: `x + width(rng)` is equivalent to `x`. In effect, this adds the necessary multiple of `width(rng)` to `x` so that it falls into `rng`.

```jldoctest
julia> Circular.to_range(0, 0..2π)
0.0

julia> Circular.to_range(4π + 1, 0..2π)
1.0

julia> Circular.to_range(5.5, -1..1)
-0.5
```
"""
to_range(x, rng::Interval) = mod(x - rng.left, width(rng)) + rng.left

""" Distance between two angles, `x` and `y`. Assumes circular structure: `x + range` is equivalent to `x`.

```jldoctest
julia> Circular.distance(0, 1)
1.0

julia> Circular.distance(0, 4π + 1)
1.0

julia> Circular.distance(0, 5.5, range=3)
0.5
```
"""
distance(x, y; range=2π) = abs(center_angle(x - y; range=range))


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
    sr = Base.Fix2(shift_range, rng => -π..π)
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
    sr = Base.Fix2(shift_range, rng => -π..π)
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
    xs = sort(to_range.(x, Ref(0..2π)))
    spacings = [diff(xs); to_range(xs[begin] - xs[end], 0..2π)]
    return 2π - maximum(spacings)
end

sample_range(x, rng::Interval) = sample_range(shift_range.(x, rng => -π..π)) * width(rng) / 2π


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


""" Assuming `data` represents a closed curve with circular structure in `f.(data)`, wrap `data` so that it goes from `minimum(rng) + eps` to `maximum(rng) - eps`. A common usecase is plotting.

```julia
julia> wrap_curve_closed(identity, [-20., 0, 100, 200]; rng=-180..180)
[-180, -160, -20, 0, 100, 180]  # approximately: endpoints are slightly moved inwards
```
"""
function wrap_curve_closed(f, data; rng)
    data = @modify(fx -> to_range(fx, rng), data |> Elements() |> f)

    is_wrap(a, b) = distance(f(a), f(b); range=width(rng)) < abs(f(a) - f(b)) * (1 - √eps(1.))
    data = @modify(data |> _ConsecutivePairs() |> If(((a, b),) -> is_wrap(a, b))) do p
        [
            p[1],
            modify(fx -> _nearest_endpoint(rng, fx; pad=√eps(1.)), p[1], f),
            set(p[2], f, NaN),
            modify(fx -> _nearest_endpoint(rng, fx; pad=√eps(1.)), p[2], f),
            p[2],
        ]
    end
    ix = findfirst(x -> isnan(f(x)), data)
    isnothing(ix) ? data : vcat(data[ix+1:end], data[begin:ix-1])
end

function _nearest_endpoint(int, x; pad)
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
