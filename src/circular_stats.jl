module Circular

using IntervalSets
import StatsBase
using Accessors: set, modify


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

shift_range(x, (from, to)::Pair) = (x - from.left) / width(from) * width(to) + to.left


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
mean(x, rng::Interval) = shift_range(mean(Iterators.map(x -> shift_range(x, rng => -π..π), x)), -π..π => rng)

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
median(x, rng::Interval) = shift_range(median(Iterators.map(x -> shift_range(x, rng => -π..π), x)), -π..π => rng)

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
    wrap_ix = findall(map(@views zip(data[begin:end-1], data[begin+1:end])) do (a, b)
        da = floor(Int, (f(a) - minimum(rng)) / width(rng))
        db = floor(Int, (f(b) - minimum(rng)) / width(rng))
        @assert db in (da - 1, da, da + 1)
        db > da || db == da && f(b) < f(a)
    end)
    wrap_ix = isempty(wrap_ix) ? [lastindex(data)] : wrap_ix

    ix = only(wrap_ix)
    obj = data[ix]
    fval = f(obj)
    obj1 = set(obj, f, maximum(rng) - √eps(fval))
    obj2 = set(obj, f, maximum(rng) + √eps(fval))
    map(@views [obj2; data[ix+1:end]; data[begin:ix]; obj1]) do x
        modify(x, f) do fx
            to_range(fx, rng)
        end
    end
end

end
