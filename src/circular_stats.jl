module CircularStats

using IntervalSets
import Statistics

function center_angle(x; at = 0, range = 2π)
    low = at - range / 2
    return mod(x - low, range) + low
end

to_range(x, rng::Interval) = mod(x - rng.left, width(rng)) + rng.left

distance(x, y; range=2π) = abs(center_angle(x - y; range=range))

shift_range(x, (from, to)) = (x - from.left) / width(from) * width(to) + to.left


resultant_vector(x) = sum(cis, x)
resultant_mean_vector(x) = resultant_vector(x) / length(x)
resultant_length(x) = abs(resultant_vector(x))
resultant_mean_length(x) = abs(resultant_mean_vector(x))


mean(x) = angle(resultant_vector(x))
mean(x, rng::Interval) = shift_range(mean(Iterators.map(x -> shift_range.(x, rng => -π..π), x)), -π..π => rng)

var(x) = 1 - resultant_mean_length(x)

std(x) = √(max(0, -2 * log(resultant_mean_length(x))))
std(x, rng::Interval) = std(Iterators.map(x -> shift_range.(x, rng => -π..π), x)) * width(rng) / 2π


function median(x::AbstractVector)
    # XXX: actually, medoid
    if length(x) == 0 return nothing end
    return minimum(a -> (sum(b -> distance(a, b), x), a), x)[2]
end

end
export CircularStats
