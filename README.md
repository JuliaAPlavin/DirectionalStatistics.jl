
<a id='Overview'></a>

<a id='Overview-1'></a>

# Overview


Directional statistics package for Julia. Currently includes several circular and spatial descriptive statistics, see reference below for details.


<a id='Reference'></a>

<a id='Reference-1'></a>

# Reference

<a id='DirectionalStatistics.CircularStats.center_angle-Tuple{Any}' href='#DirectionalStatistics.CircularStats.center_angle-Tuple{Any}'>#</a>
**`DirectionalStatistics.CircularStats.center_angle`** &mdash; *Method*.



Center angular value `x` to be within a symmetric range of length `range` around `at`, from `at - range/2` to `at + range/2`. Assumes circular structure: `x + range` is equivalent to `x`.

```julia-repl
julia> Circular.center_angle(0)
0.0

julia> Circular.center_angle(4π + 1)
1.0

julia> Circular.center_angle(4π - 1)
-1.0

julia> Circular.center_angle(10, at=0, range=3)
1.0
```


<a target='_blank' href='https://github.com/aplavin/CircularStats.jl/blob/07d694c83141c9db245a2efb9376ec821d5fd388/src/circular_stats.jl#L7-L23' class='documenter-source'>source</a><br>

<a id='DirectionalStatistics.CircularStats.distance-Tuple{Any, Any}' href='#DirectionalStatistics.CircularStats.distance-Tuple{Any, Any}'>#</a>
**`DirectionalStatistics.CircularStats.distance`** &mdash; *Method*.



Distance between two angles, `x` and `y`. Assumes circular structure: `x + range` is equivalent to `x`.

```julia-repl
julia> Circular.distance(0, 1)
1.0

julia> Circular.distance(0, 4π + 1)
1.0

julia> Circular.distance(0, 5.5, range=3)
0.5
```


<a target='_blank' href='https://github.com/aplavin/CircularStats.jl/blob/07d694c83141c9db245a2efb9376ec821d5fd388/src/circular_stats.jl#L40-L53' class='documenter-source'>source</a><br>

<a id='DirectionalStatistics.CircularStats.mad-Tuple{Any}' href='#DirectionalStatistics.CircularStats.mad-Tuple{Any}'>#</a>
**`DirectionalStatistics.CircularStats.mad`** &mdash; *Method*.



Median absolute deviation (MAD) of a collection of circular data.

```julia-repl
julia> Circular.mad([0])
0.0

julia> Circular.mad([0, 1, 2])
1.0

julia> Circular.mad([0, 2π + 1, 2])
1.0

julia> Circular.mad([0, 1, 2], -2..4) ≈ 1
true
```


<a target='_blank' href='https://github.com/aplavin/CircularStats.jl/blob/07d694c83141c9db245a2efb9376ec821d5fd388/src/circular_stats.jl#L153-L169' class='documenter-source'>source</a><br>

<a id='DirectionalStatistics.CircularStats.mean-Tuple{Any}' href='#DirectionalStatistics.CircularStats.mean-Tuple{Any}'>#</a>
**`DirectionalStatistics.CircularStats.mean`** &mdash; *Method*.



Mean of a collection of circular data.

```julia-repl
julia> Circular.mean([0, 1, 2, 3])
1.5

julia> Circular.mean([1, 2π]) ≈ 0.5
true

julia> Circular.mean([1, 5], 0..4) ≈ 1
true
```


<a target='_blank' href='https://github.com/aplavin/CircularStats.jl/blob/07d694c83141c9db245a2efb9376ec821d5fd388/src/circular_stats.jl#L63-L76' class='documenter-source'>source</a><br>

<a id='DirectionalStatistics.CircularStats.median-Tuple{Any}' href='#DirectionalStatistics.CircularStats.median-Tuple{Any}'>#</a>
**`DirectionalStatistics.CircularStats.median`** &mdash; *Method*.



Median of a collection of circular data.

Computes the median that minimizes the sum of arc distances sense. Always returns one of the datapoints, so the result is a medoid.

For discussion of different circular medians see e.g. https://hci.iwr.uni-heidelberg.de/sites/default/files/profiles/mstorath/files/storath2017fast.pdf.

```julia-repl
julia> Circular.median([0, 1, 2])
1

julia> Circular.median([0.05, 2π - 0.1, 6π + 0.1])
0.05

julia> Circular.median([0, 1, 2], -2..4)
1.0
```


<a target='_blank' href='https://github.com/aplavin/CircularStats.jl/blob/07d694c83141c9db245a2efb9376ec821d5fd388/src/circular_stats.jl#L102-L119' class='documenter-source'>source</a><br>

<a id='DirectionalStatistics.CircularStats.sample_range-Tuple{Any}' href='#DirectionalStatistics.CircularStats.sample_range-Tuple{Any}'>#</a>
**`DirectionalStatistics.CircularStats.sample_range`** &mdash; *Method*.



Sample range - the shortest arc distance encompassing all of the data in the collection.

```julia-repl
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


<a target='_blank' href='https://github.com/aplavin/CircularStats.jl/blob/07d694c83141c9db245a2efb9376ec821d5fd388/src/circular_stats.jl#L122-L144' class='documenter-source'>source</a><br>

<a id='DirectionalStatistics.CircularStats.std-Tuple{Any}' href='#DirectionalStatistics.CircularStats.std-Tuple{Any}'>#</a>
**`DirectionalStatistics.CircularStats.std`** &mdash; *Method*.



Standard deviation of a collection of circular data.

```julia-repl
julia> Circular.std([0])
0.0

julia> Circular.std([0, 1, 2, 3])
1.2216470118898806

julia> Circular.std([0, 2π])
0.0

julia> Circular.std([0, 1, 2, 3], -10..10)
1.126024231452878
```


<a target='_blank' href='https://github.com/aplavin/CircularStats.jl/blob/07d694c83141c9db245a2efb9376ec821d5fd388/src/circular_stats.jl#L82-L98' class='documenter-source'>source</a><br>

<a id='DirectionalStatistics.CircularStats.to_range-Tuple{Any, Interval}' href='#DirectionalStatistics.CircularStats.to_range-Tuple{Any, Interval}'>#</a>
**`DirectionalStatistics.CircularStats.to_range`** &mdash; *Method*.



Transform `x` to be within the range `rng` assuming circular structure: `x + width(rng)` is equivalent to `x`. In effect, this adds the necessary multiple of `width(rng)` to `x` so that it falls into `rng`.

```julia-repl
julia> Circular.to_range(0, 0..2π)
0.0

julia> Circular.to_range(4π + 1, 0..2π)
1.0

julia> Circular.to_range(5.5, -1..1)
-0.5
```


<a target='_blank' href='https://github.com/aplavin/CircularStats.jl/blob/07d694c83141c9db245a2efb9376ec821d5fd388/src/circular_stats.jl#L25-L38' class='documenter-source'>source</a><br>

<a id='DirectionalStatistics.CircularStats.var-Tuple{Any}' href='#DirectionalStatistics.CircularStats.var-Tuple{Any}'>#</a>
**`DirectionalStatistics.CircularStats.var`** &mdash; *Method*.



Variance of a collection of circular data. 


<a target='_blank' href='https://github.com/aplavin/CircularStats.jl/blob/07d694c83141c9db245a2efb9376ec821d5fd388/src/circular_stats.jl#L79' class='documenter-source'>source</a><br>

