module DirectionalStatistics

include("circular_stats.jl")
include("geometric_median.jl")

const CircularStats = Circular
export CircularStats, Circular


vec_std(A; center=mean(A))::eltype(eltype(A)) = sqrt(sum(norm.(A .- Ref(center)).^2) / (length(A) - 1))
export vec_std


# see also https://stackoverflow.com/questions/22152482/choose-n-most-distant-points-in-r

most_distant_points(points::Vector) = map(i -> points[i], most_distant_points_ix(points))

function most_distant_points_ix(points::Vector)
    dists = map(Iterators.product(points, points)) do (a, b)
        norm(a .- b)
    end
    return Tuple(findmax(dists)[2])
end
export most_distant_points, most_distant_points_ix

end
