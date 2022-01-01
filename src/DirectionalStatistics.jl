module DirectionalStatistics

include("circular_stats.jl")
include("geometric_median.jl")

const CircularStats = Circular
export CircularStats, Circular


vec_std(A; center=mean(A))::eltype(eltype(A)) = sqrt(sum(norm.(A .- Ref(center)).^2) / (length(A) - 1))
export vec_std


# see also https://stackoverflow.com/questions/22152482/choose-n-most-distant-points-in-r
""" Select a pair of most distant points in the collection. Points can be specified as real numbers (1d), complex numbers (2d), or arbitrary vectors.

```jldoctest
julia> most_distant_points([1, 2, 3])
(3, 1)

julia> most_distant_points([0, 1, 1+1im])
(1 + 1im, 0 + 0im)

julia> most_distant_points([[0, 0], [0, 1], [1, 1]])
([1, 1], [0, 0])
```
"""
most_distant_points(points::Vector) = map(i -> points[i], most_distant_points_ix(points))

""" Select indices of a pair of most distant points in the collection. Points can be specified as real numbers (1d), complex numbers (2d), or arbitrary vectors.

```jldoctest
julia> most_distant_points_ix([1, 2, 3])
(3, 1)

julia> most_distant_points_ix([0, 1, 1+1im])
(3, 1)

julia> most_distant_points_ix([[0, 0], [0, 1], [1, 1]])
(3, 1)
```
"""
function most_distant_points_ix(points::Vector)
    dists = map(Iterators.product(points, points)) do (a, b)
        norm(a .- b)
    end
    return Tuple(findmax(dists)[2])
end
export most_distant_points, most_distant_points_ix

end
